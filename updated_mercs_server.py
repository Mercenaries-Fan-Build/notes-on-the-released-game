#!/usr/bin/env python2
# -*- coding: utf-8 -*-
#
# Mercenaries 2 Abandoned Server Emulator (FESL + Theater + GameSpy)
# Python 2.7 / Ubuntu 14.04 / OpenSSL 1.0.1f (SSLv3 + RC4)
#
# Fixes in this revision:
#   * Lobbies are no longer scrubbed the instant a host's Theater socket
#     closes; a departing player is removed, the host is migrated to a
#     remaining player, and only an empty lobby is deleted.
#   * TLS handshake moved off the FESL accept loop (a stalled handshake can
#     no longer freeze new logins); handshake has a timeout.
#   * Per-connection send lock instead of one global lock (a slow client no
#     longer stalls sends to everyone).
#   * Personas are per-account, not a shared global list.
#   * UpdateStats is bound to the authenticated session user.
#   * ECNL removes the actual canceller; capacity is enforced on join.
#   * STATE.games deletes are race-safe (pop under lock).
#   * None-guards on half-open sessions; safe int() parsing of GID/ports.
#   * Debounced background DB save instead of a full dump on every message.

import os
import sys
import json
import uuid
import base64
import socket
import ssl
import struct
import random
import threading
import time

# ----------------------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------------------
SERVER_IP      = "51.81.177.161"
FESL_PORT      = 18710           # SSLv3 + RC4
THEATER_PORT   = 18715           # plaintext TCP
GAMESPY_PORT   = 27900           # UDP availability responder
MESSENGER_PORT = 13505           # advertised only; not implemented

CERT_FILE = "fesl.cer"
KEY_FILE  = "fesl.key"
DB_FILE   = "profiles.json"      # JSON Database file

CUR_TIME = '"Jan-01-2012 12:00:00 UTC"'
GAMESPY_MAGIC = 654846

# --- LOGGING TOGGLE ---
DEBUG_PACKETS = True

# --- LOG FILE ---
# Every line printed to the console is also mirrored to a timestamped file
# inside this directory (created on startup if missing).
LOG_DIR = "logs"

# --- UDP RELAY POOL CONFIG ---
RELAY_PORT_MIN = 10000
RELAY_PORT_MAX = 10100
AVAILABLE_PORTS = list(range(RELAY_PORT_MIN, RELAY_PORT_MAX + 1))
PORT_LOCK = threading.Lock()

# Max UDP payload the relay reads in one recvfrom(). The game's initial
# session / level-load datagrams can be several KB; if this buffer is smaller
# than an incoming datagram the kernel silently TRUNCATES it, which presents
# as a joiner stuck on a black screen while the host already shows them as
# connected. 65535 = the largest possible UDP payload, so we never truncate.
RELAY_RECV_BUF = 65535

# ----------------------------------------------------------------------------
# Logging (console + file)
# ----------------------------------------------------------------------------
# The whole server uses plain `print` (Python 2 statement form). Rather than
# rewrite every call site, we mirror stdout/stderr into a timestamped log file
# by swapping sys.stdout / sys.stderr for a small tee at startup. The vintage
# code stays untouched, but you get a persistent, timestamped log you can
# review later or attach to a bug report.
_LOG_LOCK = threading.Lock()

class _FileLogWriter(object):
    """Timestamped, thread-safe writer to the log file. Shared by the stdout
    and stderr tees so concurrent prints from relay/handler threads neither
    interleave mid-line nor double-stamp the same line."""
    def __init__(self, handle):
        self.handle = handle
        self._line_start = True

    def write_locked(self, data):
        # Caller already holds _LOG_LOCK. Walk char-by-char so a timestamp is
        # written exactly once, at the start of each line, even when `print`
        # splits a line across two writes (text, then newline).
        for ch in data:
            if self._line_start and ch != '\n':
                self.handle.write('[{0}] '.format(time.strftime('%Y-%m-%d %H:%M:%S')))
                self._line_start = False
            self.handle.write(ch)
            if ch == '\n':
                self._line_start = True
        self.handle.flush()

class _Tee(object):
    """Sends every write to a console stream AND the shared log file."""
    def __init__(self, console_stream, file_writer):
        self.console = console_stream
        self.file_writer = file_writer

    def write(self, data):
        if not data:
            return
        with _LOG_LOCK:
            try:
                self.console.write(data)
            except Exception:
                pass
            try:
                self.file_writer.write_locked(data)
            except Exception:
                pass

    def flush(self):
        with _LOG_LOCK:
            try:
                self.console.flush()
            except Exception:
                pass
            try:
                self.file_writer.handle.flush()
            except Exception:
                pass

def init_logging():
    """Swap stdout/stderr for tees that mirror to a per-run log file.
    Returns the log file path so it can be announced at startup."""
    log_dir = LOG_DIR
    try:
        if not os.path.isdir(log_dir):
            os.makedirs(log_dir)
    except Exception:
        log_dir = "."   # fall back to cwd if the dir can't be created
    fname = os.path.join(
        log_dir, "mercs2_server_{0}.log".format(time.strftime('%Y-%m-%d_%H-%M-%S')))
    handle = open(fname, "a")
    writer = _FileLogWriter(handle)
    # Capture the *current* real streams before replacing them.
    console_out = sys.stdout
    console_err = sys.stderr
    sys.stdout = _Tee(console_out, writer)
    sys.stderr = _Tee(console_err, writer)
    return fname

# ----------------------------------------------------------------------------
# UDP Relay Engine
# ----------------------------------------------------------------------------
def allocate_relay_ports():
    with PORT_LOCK:
        if len(AVAILABLE_PORTS) >= 2:
            return AVAILABLE_PORTS.pop(0), AVAILABLE_PORTS.pop(0)
        return None, None

def free_relay_ports(port1, port2):
    with PORT_LOCK:
        AVAILABLE_PORTS.extend([port1, port2])

def threaded_udp_relay(host_port, joiner_port, game_id, expected_ips):
    """UDP relay between a lobby's host and joiner.

    expected_ips is a shared dict {'host': <ip>, 'joiner': <ip or None>}.
    Every inbound packet's source IP must match the corresponding
    expected IP before we'll lock the (ip, port) tuple for that
    direction or forward anything. After the first matching packet,
    the (ip, port) is locked and subsequent packets must match it
    exactly; anything else is dropped silently. This stops a port
    scanner from claiming the host or joiner identity and hijacking
    the session.

    The joiner IP may legitimately be None for a brief window between
    lobby create and EnterGame; during that window joiner-side packets
    are dropped.
    """
    sock_host = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock_joiner = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    # Bind early; on failure (port in use, permission denied, stale
    # TIME_WAIT, etc.) free the ports back to the pool so they don't
    # leak. Previously a bind failure here drained the pool silently.
    try:
        sock_host.bind(('0.0.0.0', host_port))
        sock_joiner.bind(('0.0.0.0', joiner_port))
    except Exception as e:
        print "[!] RELAY: bind failed for ports {0}/{1} (Game {2}): {3}".format(
            host_port, joiner_port, game_id, e)
        sock_host.close()
        sock_joiner.close()
        free_relay_ports(host_port, joiner_port)
        return

    # State tracking for the NAT mapping. endpoints holds the
    # currently-locked (ip, port) for each side. last_active drives
    # the idle-timeout watchdog below.
    endpoints = {'host': None, 'joiner': None}
    running = [True]
    last_active = [time.time()]
    max_seen = {'host': 0, 'joiner': 0}   # largest datagram per direction (diagnostic)

    def relay(src_sock, dst_sock, src_key, dst_key):
        src_sock.settimeout(1.0)  # hoisted; previously set every iteration
        while running[0]:
            try:
                data, addr = src_sock.recvfrom(RELAY_RECV_BUF)
            except socket.timeout:
                continue
            except Exception as e:
                print "[!] RELAY: {0}->{1} recv error (Game {2}): {3}".format(
                    src_key, dst_key, game_id, e)
                continue

            locked = endpoints[src_key]
            if locked is None:
                # No endpoint locked yet for this direction. Accept the
                # first packet whose source IP matches what FESL told us
                # to expect, and lock the full (ip, port) tuple from
                # then on. Drop anything else; that's almost certainly
                # a probe.
                expected_ip = expected_ips.get(src_key)
                if expected_ip is None:
                    # We haven't been told who to expect yet (joiner
                    # hasn't entered the game). Can't safely lock.
                    continue
                if addr[0] != expected_ip:
                    # Probable hijack attempt. Could log at debug level
                    # but unconditional logging would help port scanners
                    # confirm a live relay; stay quiet.
                    continue
                endpoints[src_key] = addr
                print "[*] RELAY: locked {0} endpoint to {1} for Game {2}".format(
                    src_key, addr, game_id)
            elif addr != locked:
                # Locked endpoint mismatch. Drop spoofed traffic.
                continue

            last_active[0] = time.time()

            # Diagnostic: surface the largest datagram seen per direction. If
            # this prints a value above the OLD 2048 buffer, that datagram was
            # being truncated before -- a prime suspect for the black screen.
            if DEBUG_PACKETS and len(data) > max_seen[src_key]:
                max_seen[src_key] = len(data)
                print "[*] RELAY: new max {0}->{1} datagram {2} bytes (Game {3})".format(
                    src_key, dst_key, len(data), game_id)

            dst = endpoints[dst_key]
            if dst:
                try:
                    dst_sock.sendto(data, dst)
                except Exception as e:
                    print "[!] RELAY: {0}->{1} send error (Game {2}): {3}".format(
                        src_key, dst_key, game_id, e)

    t1 = threading.Thread(target=relay, args=(sock_host, sock_joiner, 'host', 'joiner'))
    t2 = threading.Thread(target=relay, args=(sock_joiner, sock_host, 'joiner', 'host'))
    t1.daemon = True
    t2.daemon = True
    t1.start()
    t2.start()

    print "[*] RELAY: Allocated ports {0} (Host) and {1} (Joiner) for Game {2}".format(host_port, joiner_port, game_id)

    # The Watchdog Loop
    while game_id in STATE.games:
        # If 600 seconds pass with zero packets, assume a crash/Alt-F4
        if time.time() - last_active[0] > 600.0:
            print "[!] RELAY: Lobby {0} timed out (Crash/Alt-F4 detected).".format(game_id)
            # Race-safe delete: pop under the state lock so this can't collide
            # with the Theater-disconnect / RGAM paths and raise KeyError.
            with STATE.lock:
                STATE.games.pop(game_id, None)
            break

        time.sleep(1)

    # Teardown and Cleanup
    running[0] = False
    sock_host.close()
    sock_joiner.close()
    free_relay_ports(host_port, joiner_port)
    print "[*] RELAY: Recovered ports {0} and {1} for Game {2}".format(host_port, joiner_port, game_id)

# ----------------------------------------------------------------------------
# Wire format
# ----------------------------------------------------------------------------
def _quote(v):
    return str(v).replace('=', '%3d')

def _unquote(v):
    return v.replace('%3d', '=')

def _flatten(name, obj):
    d = {}
    if isinstance(obj, dict):
        for k, sub in obj.items():
            key = "{0}.{1}".format(name, k) if name else k
            d.update(_flatten(key, sub))
    elif isinstance(obj, (list, tuple)):
        d = {"{0}.[]".format(name): len(obj)}
        for i, e in enumerate(obj):
            d.update(_flatten("{0}.{1}".format(name, i), e))
    else:
        d = {name: obj}
    return d

class FESLMessage(object):
    def __init__(self, type_id="XXXX", flags=0, data=None):
        self.type_id = type_id
        self.flags = flags
        self.data = dict(data) if data else {}

    def serialize(self):
        flat = _flatten(None, self.data)
        body = '\n'.join("{0}={1}".format(k, _quote(v)) for k, v in flat.items()) + '\x00'
        length = len(body) + 12
        header = struct.pack('!4sII', self.type_id, self.flags, length)
        return header + body

    @staticmethod
    def parse(raw):
        type_id, flags, length = struct.unpack('!4sII', raw[:12])
        body = raw[12:length].strip('\x00\n')
        msg = FESLMessage(type_id, flags)
        if body:
            for line in body.split('\n'):
                if '=' in line:
                    k, v = line.split('=', 1)
                    msg.data[k] = _unquote(v)
        return msg

def extract_messages(buf):
    msgs = []
    while len(buf) >= 12:
        _, _, length = struct.unpack('!4sII', buf[:12])
        if length < 12 or length > 0x10000:
            return msgs, ''
        if len(buf) < length:
            break
        msgs.append(FESLMessage.parse(buf[:length]))
        buf = buf[length:]
    return msgs, buf

# --- Per-connection send locking --------------------------------------------
# Two threads can legitimately write to the same socket (a handler + the
# heartbeat, or one session's handler routing EGRQ/EGEG to another session's
# Theater conn), so writes to a given socket must be serialized. Do it per
# connection, NOT with one global lock -- a global lock lets a single slow
# reader (blocking sendall) stall sends to every other client.
_CONN_LOCKS = {}
_CONN_LOCKS_META = threading.Lock()

def _conn_lock(conn):
    with _CONN_LOCKS_META:
        lock = _CONN_LOCKS.get(conn)
        if lock is None:
            lock = threading.Lock()
            _CONN_LOCKS[conn] = lock
        return lock

def _drop_conn_lock(conn):
    with _CONN_LOCKS_META:
        _CONN_LOCKS.pop(conn, None)

def send_msg(conn, msg):
    try:
        with _conn_lock(conn):
            conn.sendall(msg.serialize())
    except Exception:
        pass  # Socket likely closed

def _log_msg(direction, ep, msg, key):
    ident = msg.data.get(key, '')
    print "{0} {1} id={2} {3}={4}".format(direction, ep, msg.type_id, key, ident)

    if DEBUG_PACKETS and msg.data:
        print "      PAYLOAD: {0}".format(msg.data)

# ----------------------------------------------------------------------------
# Shared state & Account System
# ----------------------------------------------------------------------------
class User(object):
    def __init__(self, uid, name):
        self.id = uid
        self.name = name
        self.session = None

        self.known_ips = set()
        self.personas = []          # per-account personas (was a shared global)
        self.stats = {
            'logins': 0,
            'games_hosted': 0,
            'games_joined': 0
        }

    def to_dict(self):
        # Snapshot each mutable field (dict()/list() are atomic under the GIL)
        # so a concurrent handler mutation can't trip json.dump mid-write.
        return {
            'id': self.id,
            'name': self.name,
            'known_ips': list(self.known_ips),
            'personas': list(self.personas),
            'stats': dict(self.stats)
        }

    def load_from_dict(self, data):
        self.id = data.get('id', self.id)
        self.known_ips = set(data.get('known_ips', []))
        self.personas = list(data.get('personas', []))
        self.stats.update(data.get('stats', {}))

class EnterGameRequest(object):
    def __init__(self):
        self.id = -1634156166
        self.pid = 0
        self.user = None
        self.ipIn = (None, None)
        self.ipEx = (None, None)

class Game(object):
    def __init__(self):
        self.id = 0
        self.lid = 257
        self.host = None
        self.players = []
        self.requests = {}
        self.ekey = 'T1LZMJuD6PVPPjQsjv4r6Q=='
        self.secret = ('kYcQzhZU7rWVNTl49aTFjT2bDDOrZ/ATI+pBcc5h5PQ'
                       'fQi4cSf6rNDXlSGuaIEfdLKsYg6CjNtvugPm11NfuBg==')
        # Unique per lobby (was a shared constant) so nothing keys two live
        # lobbies to the same UGID.
        self.uid = str(uuid.uuid4())
        self.ipEx = (None, None)
        self.ipIn = (None, None)
        self.slots = 0
        self.info = {}
        self.relay_ports = (None, None) # Added to track active relay ports
        # Shared with the relay thread: {'host': <ip>, 'joiner': <ip or None>}.
        # The relay validates the source IP of every UDP packet against
        # the corresponding entry before forwarding, preventing a port
        # scanner from hijacking an active session. The host IP is set
        # at lobby create; the joiner IP gets filled in when a player
        # joins via _handle_enter_game.
        self.relay_expected_ips = None

class Session(object):
    def __init__(self, fesl_conn=None, client_ip="Unknown"):
        self.user = None
        self.lkey = None
        self.fesl_conn = fesl_conn
        self.theater_conn = None
        self.client_ip = client_ip
        # Predicates from this player's most recent pnow (custom) search, so a
        # follow-up GID=0 GDAT can serve a lobby that matches what they searched
        # for rather than just any available lobby.
        self.pnow_filters = []

        self._stop_heartbeat = threading.Event()
        self._heartbeat_thread = None

    def start_heartbeat(self):
        if self._heartbeat_thread is None:
            self._heartbeat_thread = threading.Thread(target=self._heartbeat_loop)
            self._heartbeat_thread.daemon = True
            self._heartbeat_thread.start()

    def stop_heartbeat(self):
        self._stop_heartbeat.set()

    def _heartbeat_loop(self):
        target_interval = 120
        last_ping = time.time()

        while not self._stop_heartbeat.is_set():
            time.sleep(1)
            if time.time() - last_ping >= target_interval:
                last_ping = time.time()
                if self.fesl_conn:
                    try:
                        ping_msg = FESLMessage('fsys', 0, {'TXN': 'Ping'})
                        send_msg(self.fesl_conn, ping_msg)

                        mc_msg = FESLMessage('fsys', 0x80000000, {
                            'TXN': 'MemCheck',
                            'salt': random.getrandbits(32),
                            'type': 0,
                            'memcheck': []
                        })
                        send_msg(self.fesl_conn, mc_msg)
                    except Exception:
                        self.stop_heartbeat()

class TheaterState(object):
    def __init__(self):
        self.users = {}
        self.sessions = {}
        self.games = {}
        self.last_user_id = 0
        self.last_game_id = 1000
        self.lock = threading.Lock()
        self._dirty = threading.Event()

        self.load_database()

        # Debounced background saver. Handlers call mark_dirty() (cheap); this
        # thread coalesces bursts and writes at most ~every couple of seconds,
        # instead of a full JSON dump on every login / stat / known-ip change.
        saver = threading.Thread(target=self._save_loop)
        saver.daemon = True
        saver.start()

    def load_database(self):
        if os.path.exists(DB_FILE):
            try:
                with open(DB_FILE, 'r') as f:
                    data = json.load(f)
                    for name, udata in data.items():
                        u = User(udata.get('id', self.last_user_id + 1), name)
                        u.load_from_dict(udata)
                        self.users[name] = u
                        if u.id > self.last_user_id:
                            self.last_user_id = u.id
                print "[*] DATABASE: Loaded {0} profiles from {1}.".format(len(self.users), DB_FILE)
            except Exception as e:
                print "[!] DATABASE ERROR: Could not load {0}: {1}".format(DB_FILE, e)

    # Existing call sites call save_database(); keep the name but just flag the
    # DB dirty and let the background saver flush it.
    def save_database(self):
        self._dirty.set()

    def mark_dirty(self):
        self._dirty.set()

    def _save_loop(self):
        while True:
            self._dirty.wait()      # block until something changed
            time.sleep(2.0)         # let a burst of changes settle, then flush
            self._dirty.clear()
            self._save_now()

    def _save_now(self):
        with self.lock:
            try:
                data = {name: u.to_dict() for name, u in self.users.items()}
                with open(DB_FILE, 'w') as f:
                    json.dump(data, f, indent=4)
            except Exception as e:
                print "[!] DATABASE ERROR: Could not save to disk: {0}".format(e)

    def create_user(self, name):
        with self.lock:
            self.last_user_id += 1
            u = User(self.last_user_id, name)
            self.users[name] = u
            return u

    def get_user(self, name):
        return self.users.get(name)

    def get_or_create(self, name):
        return self.get_user(name) or self.create_user(name)

    def register_session(self, lkey, session):
        with self.lock:
            self.sessions[lkey] = session

    def get_session(self, lkey):
        return self.sessions.get(lkey)

    def find_user(self, uid):
        try:
            uid = int(uid)
        except (TypeError, ValueError):
            return None
        for u in self.users.values():
            if u.id == uid:
                return u
        return None

    def find_game(self, username):
        for g in self.games.values():
            if g.host and g.host.name == username:
                return g
        return None

    def generate_game_id(self):
        with self.lock:
            self.last_game_id += 1
            return self.last_game_id

# Mirror all output to a timestamped log file before anything else prints
# (this captures the database-load line emitted by TheaterState() below).
LOG_PATH = init_logging()

STATE = TheaterState()

def gen_lkey():
    return base64.urlsafe_b64encode(os.urandom(20)).rstrip('=') + '.'

def _entitlement_block():
    return [{'gameFeatureId': 6014, 'status': 0, 'message': '',
             'entitlementExpirationDate': '', 'entitlementExpirationDays': -1}]

def to_ea_mapping(d):
    out = dict(('{%s}' % k, v) for k, v in d.items())
    out['{}'] = len(out)
    return out

_TELEMETRY_RAW = ('159.153.244.83,9988,enFI,'
    '^\xf2\xf0\xbd\xaf\x88\xf8\xca\x94\x96\x9f\x96\xdd\xcd\xc6\x9b\xe9\xad\xd7'
    '\xa8\x8a\xb6\xec\xda\xb0\xec\xea\xcd\xe3\xc2\x84\x8c\x98\xb1\xc4\x99\x9b'
    '\xa6\xec\x8c\x9b\xb9\xc6\x89\xe3\xc2\x84\x8c\x98\xb0\xe0\xc0\x81\x83\x86'
    '\x8c\x98\xe1\xc6\xd1\xa9\x86\xa6\x8d\xb1\xac\x8a\x85\xba\x94\xa8\xd3\xa2'
    '\xd3\xde\x8c\xf2\xb4\xc8\xd4\xa0\xb3\xd8\xc4\x91\xb3\x86\xcc\x99\xb8\xe2'
    '\xc8\xb1\x83\x87\xcb\xb2\xee\x8c\xa5\x82\n')

# ----------------------------------------------------------------------------
# Small parsing / lookup helpers
# ----------------------------------------------------------------------------
def _int(v, default=0):
    try:
        return int(v)
    except (TypeError, ValueError):
        return default

def _gid_int(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return None

def _game_by_gid(v):
    gid = _gid_int(v)
    return STATE.games.get(gid) if gid is not None else None

# ----------------------------------------------------------------------------
# FESL Transaction Handling
# ----------------------------------------------------------------------------
def handle_fesl_message(session, msg):
    txn = msg.data.get('TXN', '')
    reply = FESLMessage(msg.type_id, 0x80000000 | (msg.flags & 0xFF))
    reply.data['TXN'] = txn
    out = [reply]

    if msg.type_id == 'fsys':
        if txn == 'Hello':
            reply.data.update({
                'activityTimeoutSecs': 0,
                'curTime': CUR_TIME,
                'messengerIp': SERVER_IP,
                'messengerPort': MESSENGER_PORT,
                'theaterIp': SERVER_IP,
                'theaterPort': THEATER_PORT,
                'domainPartition.domain': 'eagames',
                'domainPartition.subDomain': 'MERCS2',
            })
            mc = FESLMessage('fsys', 0x80000000,
                             {'TXN': 'MemCheck',
                              'salt': random.getrandbits(32),
                              'type': 0,
                              'memcheck': []})
            out.append(mc)
            session.start_heartbeat()

        elif txn in ('MemCheck', 'Goodbye', 'Ping'):
            out = []
        elif txn == 'GetPingSites':
            reply.data.update({
                'minPingSitesToPing': 0,
                'pingSite': [
                    {'addr': SERVER_IP, 'name': 'eu-ip', 'type': 0},
                    {'addr': SERVER_IP, 'name': 'ec-ip', 'type': 0},
                    {'addr': SERVER_IP, 'name': 'wc-ip', 'type': 0},
                ]})
        else:
            if DEBUG_PACKETS: print "[!] UNHANDLED fsys TXN={0}".format(txn)

    elif msg.type_id == 'acct':
        if txn in ('NuLogin', 'Login'):
            name = msg.data.get('name', 'Player') if txn == 'Login' else msg.data.get('nuid', 'Player@ea.com')
            session.user = STATE.get_or_create(name)
            session.user.session = session
            session.lkey = gen_lkey()
            STATE.register_session(session.lkey, session)

            session.user.known_ips.add(session.client_ip)
            session.user.stats['logins'] += 1
            STATE.save_database()

            if DEBUG_PACKETS:
                print "      [*] ACCOUNT: {0} logged in. Total Logins: {1} | Known IPs: {2}".format(
                    session.user.name, session.user.stats['logins'], list(session.user.known_ips))

            reply.data.update({
                'displayName': session.user.name,
                'userId': session.user.id,
                'profileId': session.user.id,
                'lkey': session.lkey,
                'entitledGameFeatureWrappers': _entitlement_block(),
            })

        elif txn == 'NuGetPersonas':
            # Personas belong to the logged-in account, not everyone.
            reply.data['personas'] = list(session.user.personas) if session.user else []
        elif txn == 'NuAddPersona':
            if session.user:
                session.user.personas.append(msg.data.get('name', ''))
                STATE.save_database()
        elif txn == 'NuLoginPersona':
            name = msg.data.get('name', 'Player')
            session.user = STATE.get_or_create(name)
            session.user.session = session
            session.lkey = gen_lkey()
            STATE.register_session(session.lkey, session)
            reply.data['lkey'] = session.lkey
            reply.data['profileId'] = session.user.id
            reply.data['userId'] = session.user.id

        elif txn == 'NuEntitleGame':
            out = []
        elif txn == 'GetTelemetryToken':
            reply.data.update({
                'enabled': 'CA,MX,PR,US,VI',
                'disabled': '',
                'filters': '',
                'telemetryToken': base64.b64encode(_TELEMETRY_RAW),
            })
        elif txn == 'GameSpyPreAuth':
            reply.data['challenge'] = 'gnbzlxhv'
            reply.data['ticket'] = (
                'CCUBnHUPERml+OVgejfpuXqQS9VmzKBnBalrwEnQ8HBNvxOl/8qpukAzGCJ1HzT'
                'undOT8w6gFXNtNk4bDJnd0xtgw==')
            out.append(FESLMessage('fsys', 0, {'TXN': 'Ping'}))
        elif txn == 'LookupUserInfo':
            user = STATE.find_user(msg.data.get('userInfo.0.userId'))
            if user:
                reply.data['userInfo'] = [{'userName': user.name,
                                           'userId': user.id,
                                           'namespace': 'MAIN'}]
        else:
            if DEBUG_PACKETS: print "[!] UNHANDLED acct TXN={0}".format(txn)

    elif msg.type_id == 'subs':
        if txn == 'GetEntitlementByBundle':
            reply.data.update({
                'pricingOptionId': 'REG-PC-MERCENARIES2-UNLOCK-1',
                'name': '"Mercenaries 2 UNLOCK 1 PC"',
                'description': '"Mercenaries 2 UNLOCK 1 PC"',
                'type': 1,
                'entitlementStatus': 0,
                'entitlementStatusDesc': 'ACTIVE',
                'entitlementSuspendDate': '',
            })
        else:
            if DEBUG_PACKETS: print "[!] UNHANDLED subs TXN={0}".format(txn)

    elif msg.type_id == 'pnow':
        if txn == 'Start':
            gid = 605
            partition = msg.data.get('partition.partition', '/eagames/MERCS2')
            reply.data['id.id'] = gid
            reply.data['id.partition'] = partition

            # Apply the custom-search predicates (contract/mission, friendly
            # fire, version, ...) and remember them on the session so the
            # follow-up GID=0 GDAT serves a matching lobby. Version is now just
            # another filter: every client reports the same patched value, so
            # it matches naturally and needs no special handling.
            filters = _pnow_filters(msg.data)
            session.pnow_filters = filters
            matching = [g.id for g in STATE.games.values() if _game_matches(g, filters)]
            if DEBUG_PACKETS:
                print "      [*] PLAYNOW: search filters={0} -> {1} match(es): {2}".format(
                    filters, len(matching), matching)

            status = FESLMessage('pnow', 0x80000000, {
                'TXN': 'Status',
                'id.id': gid,
                'id.partition': partition,
                'sessionState': 'COMPLETE',
                'props': to_ea_mapping({
                    'availableServerCount': len(matching),
                    'games': matching,
                    'resultType': 'LIST'
                }),
            })
            out.append(status)

    elif msg.type_id == 'rank':
        if txn == 'UpdateStats':
            # SECURITY: apply stats to the authenticated session user only. The
            # client-supplied target name ('t') is logged but not trusted, so a
            # client can't rewrite another account's stats or spawn profile rows.
            owner = session.user
            if owner is None:
                if DEBUG_PACKETS: print "      [!] UpdateStats ignored: no logged-in user"
            else:
                try:
                    num_users = int(msg.data.get('u.[]', 0))
                    for u_idx in range(num_users):
                        u_prefix = 'u.{0}.'.format(u_idx)
                        num_stats = int(msg.data.get(u_prefix + 's.[]', 0))

                        for s_idx in range(num_stats):
                            s_prefix = u_prefix + 's.{0}.'.format(s_idx)

                            target_name = msg.data.get(s_prefix + 't')
                            stat_key = msg.data.get(s_prefix + 'k')
                            stat_value = msg.data.get(s_prefix + 'v')

                            if stat_key and stat_value is not None:
                                owner.stats[stat_key] = str(stat_value)
                                if DEBUG_PACKETS:
                                    print "      [*] STAT TRACKER: {0}'s '{1}' set to {2} (reported target={3!r})".format(
                                        owner.name, stat_key, stat_value, target_name)

                    STATE.save_database()
                except Exception as e:
                    if DEBUG_PACKETS: print "      [!] Error parsing UpdateStats: {0}".format(e)

        elif txn == 'GetRankedStats':
            name = session.user.name if session.user else 'Player'
            stats_list = []

            try:
                num_keys = int(msg.data.get('keys.[]', 0))
                for i in range(num_keys):
                    req_key = msg.data.get('keys.{0}'.format(i))
                    if req_key:
                        val = session.user.stats.get(req_key, "0.0000") if session.user else "0.0000"
                        stats_list.append({
                            'key': req_key,
                            'rank': 4390,
                            'text': name,
                            'value': val
                        })
            except Exception:
                pass

            if not stats_list:
                stats_list = [{'key': 'vz', 'rank': 4390, 'text': name, 'value': '0.0000'}]

            reply.data['stats'] = stats_list

    else:
        if DEBUG_PACKETS: print "[!] UNHANDLED id={0} TXN={1}".format(msg.type_id, txn)

    return out

# ----------------------------------------------------------------------------
# Theater Transaction Handling
# ----------------------------------------------------------------------------
def _theater_reply(msg, extra=None):
    r = FESLMessage(msg.type_id, 0)
    r.data['TID'] = msg.data.get('TID', '')
    if extra:
        r.data.update(extra)
    return r

def _peer_ip(conn):
    try:
        return conn.getpeername()[0]
    except Exception:
        # Return None rather than SERVER_IP: on the (rare) failure path we'd
        # otherwise tell the relay to expect the server's own IP, which never
        # matches a real client. None just means "unknown", not "impersonate".
        return None

def _pnow_filters(data):
    """Extract custom-search predicates from a pnow Start request.

    The client sends paired props, e.g.:
        players.0.props.{filter-FriendlyFire}     = '1'
        players.0.props.{filterToGame-FriendlyFire} = 'U-FriendlyFire'
    meaning "match games whose B-U-FriendlyFire == 1". Returns a list of
    (lobby_field, wanted_value), e.g. ('B-U-FriendlyFire', '1'). Version is
    handled as an ordinary filter ({filterToGame-version} -> 'B-version');
    every client reports the same patched value so it matches naturally."""
    fpre = 'players.0.props.{filter-'
    mpre = 'players.0.props.{filterToGame-'
    filters = []
    for k, v in data.items():
        if k.startswith(fpre) and k.endswith('}'):
            name = k[len(fpre):-1]                 # e.g. 'FriendlyFire', 'Mission', 'version'
            game_field = data.get(mpre + name + '}')   # e.g. 'U-FriendlyFire'
            if game_field:
                filters.append(('B-' + game_field, v))   # -> 'B-U-FriendlyFire'
    return filters

def _game_matches(game, filters):
    """True if the lobby satisfies every custom-search predicate."""
    for field, want in filters:
        have = game.info.get(field)
        if have is None or str(have) != str(want):
            return False
    return True

def _pick_available_game(exclude_user=None, filters=None):
    """Return a joinable lobby for Play Now (GID=0) requests, or None.
    Skips full lobbies, the requester's own lobby, and anything that doesn't
    satisfy the active custom-search filters; prefers the newest."""
    candidates = []
    for g in STATE.games.values():
        if not g.host:
            continue
        if exclude_user is not None and g.host is exclude_user:
            continue
        if filters and not _game_matches(g, filters):
            continue
        try:
            cap = int(g.slots) if g.slots is not None else 0
        except (TypeError, ValueError):
            cap = 0
        if cap and len(g.players) >= cap:
            continue   # full
        candidates.append(g)
    if not candidates:
        return None
    candidates.sort(key=lambda g: g.id, reverse=True)   # newest first
    return candidates[0]

def _drop_user_from_lobby(user):
    """Take `user` out of whatever lobby they're in when their Theater
    connection drops.

    Host loss ENDS the session: Mercs2 co-op is host-authoritative, so without
    the host the game can't continue -- tear the whole lobby down. Any joiners
    are dropped with it (their clients detect the host is gone on their own,
    and the relay watchdog frees the ports once the game disappears).

    A joiner leaving just frees their slot and keeps the lobby for the host.

    Returns a short log string, or None if the user wasn't in a lobby."""
    with STATE.lock:
        game = None
        for g in STATE.games.values():          # Py2 .values() -> snapshot list
            if g.host is user or user in g.players:
                game = g
                break
        if game is None:
            return None

        if game.host is user:
            # Host gone -> session over. Close the whole lobby.
            STATE.games.pop(game.id, None)
            dropped = len(game.players)
            if dropped:
                return "host {0} left -> lobby {1} closed ({2} joiner(s) dropped)".format(
                    user.name, game.id, dropped)
            return "host {0} left -> lobby {1} closed".format(user.name, game.id)

        # A joiner left: free their slot, keep the lobby for the host.
        while user in game.players:
            game.players.remove(user)
        return "{0} left lobby {1} ({2} still in)".format(user.name, game.id, len(game.players))

def _handle_create_game(ctx, msg):
    sess = ctx['session']
    g = Game()
    g.id = STATE.generate_game_id()
    g.host = sess.user if sess else None
    g.ipEx = (_peer_ip(ctx['conn']), msg.data.get('PORT'))
    g.ipIn = (msg.data.get('INT-IP'), msg.data.get('INT-PORT'))
    g.slots = msg.data.get('MAX-PLAYERS')
    g.info = dict((k, v) for k, v in msg.data.items() if k.startswith('B-'))

    STATE.games[g.id] = g

    if g.host:
        g.host.stats['games_hosted'] += 1
        STATE.save_database()

    # --- START UDP RELAY THREAD ---
    g.relay_ports = allocate_relay_ports()
    if g.relay_ports[0] and g.relay_ports[1]:
        # Shared with the relay thread for source-IP validation. The
        # host IP is known now (peer IP of the theater connection that
        # just created this lobby). The joiner IP gets filled in by
        # _handle_enter_game once a player joins; until then the relay
        # drops joiner-side packets rather than locking to a probe.
        g.relay_expected_ips = {'host': g.ipEx[0], 'joiner': None}
        t = threading.Thread(target=threaded_udp_relay,
                             args=(g.relay_ports[0], g.relay_ports[1],
                                   g.id, g.relay_expected_ips))
        t.daemon = True
        t.start()
    else:
        print "[!] RELAY: Port pool exhausted! Lobby {0} created without relay.".format(g.id)

    return [_theater_reply(msg, {
        'EKEY': g.ekey, 'GID': g.id, 'J': 0, 'JOIN': 0, 'LID': g.lid,
        'MAX-PLAYERS': g.slots, 'SECRET': g.secret, 'UGID': g.uid})]

def _handle_enter_game(ctx, msg):
    joiner = ctx['session']
    if 'GID' in msg.data:
        game = _game_by_gid(msg.data.get('GID'))
    else:
        game = STATE.find_game(msg.data.get('USER'))
    if not game or game.host is None:
        return [_theater_reply(msg, {})]

    rq = EnterGameRequest()
    rq.user = joiner.user if joiner else None
    if rq.user is None:
        # Theater client that never completed a FESL login; nothing to route.
        return [_theater_reply(msg, {})]

    # Capacity guard: don't over-fill a lobby via a direct GID join.
    try:
        cap = int(game.slots) if game.slots is not None else 0
    except (TypeError, ValueError):
        cap = 0
    if cap and rq.user not in game.players and len(game.players) >= cap:
        if DEBUG_PACKETS:
            print "      [!] EGAM rejected: lobby {0} full ({1}/{2})".format(
                game.id, len(game.players), cap)
        return [_theater_reply(msg, {})]

    rq.pid = min(len(game.players) + 1, 2)
    rq.ipIn = (msg.data.get('R-INT-IP'), _int(msg.data.get('R-INT-PORT', 0)))
    rq.ipEx = (_peer_ip(ctx['conn']), msg.data.get('PORT'))
    game.requests[rq.pid] = rq

    # Tell the relay (if one is running for this lobby) which source IP
    # to accept on the joiner side. Single-key dict assignment is atomic
    # under CPython's GIL, so no lock is needed.
    if game.relay_expected_ips is not None:
        game.relay_expected_ips['joiner'] = rq.ipEx[0]

    reply = _theater_reply(msg, {'GID': game.id, 'LID': game.lid})

    # --- OVERRIDE HOST CONNECTION PARAMS ---
    host_port = game.relay_ports[0] if game.relay_ports[0] else rq.ipEx[1]

    rdict = {'PTYPE': 'P', 'GID': game.id, 'IP': SERVER_IP, 'PORT': host_port,
             'LID': game.lid, 'NAME': rq.user.name, 'UID': rq.user.id,
             'PID': rq.pid, 'R-INT-IP': rq.ipIn[0], 'R-INT-PORT': rq.ipIn[1],
             'TICKET': rq.id}

    if game.host is not rq.user:
        rdict.update({'R-USER': game.host.name, 'R-U-USERID': game.host.id})

    host_sess = game.host.session
    if host_sess and host_sess.theater_conn:
        egrq_msg = FESLMessage('EGRQ', 0, rdict)
        print "THTR  OUT (To Host) id=EGRQ (Asking host to accept routing to VPS)"
        send_msg(host_sess.theater_conn, egrq_msg)
    return [reply]

def _handle_enter_game_response(ctx, msg):
    reply = _theater_reply(msg, {})
    game = _game_by_gid(msg.data.get('GID'))
    if not game or game.host is None:
        return [reply]
    pid = _int(msg.data.get('PID', 0))
    rq = game.requests.get(pid)
    if not rq or rq.user is None:
        return [reply]
    if rq.user not in game.players:
        game.players.append(rq.user)

    rq.user.stats['games_joined'] += 1
    STATE.save_database()

    # --- OVERRIDE JOINER CONNECTION PARAMS ---
    joiner_port = game.relay_ports[1] if game.relay_ports[1] else game.ipEx[1]

    joiner_sess = rq.user.session if rq.user else None
    if joiner_sess and joiner_sess.theater_conn:
        egeg_msg = FESLMessage('EGEG', 0, {
            'LID': game.lid, 'GID': game.id, 'UGID': game.uid,
            'HUID': game.host.id, 'I': SERVER_IP, 'P': joiner_port,
            'INT-IP': game.ipIn[0], 'INT-PORT': game.ipIn[1], 'PL': 'pc',
            'PID': pid, 'EKEY': game.ekey, 'TICKET': rq.id})
        print "THTR  OUT (To Joiner) id=EGEG (Clear to connect to VPS Relay!)"
        send_msg(joiner_sess.theater_conn, egeg_msg)
    return [reply]

def handle_theater_message(ctx, msg):
    mid = msg.type_id
    reply = _theater_reply(msg)
    out = [reply]

    if mid == 'CONN':
        reply.data.update({'TIME': int(time.time()),
                           'activityTimeoutSecs': 86400, 'PROT': 2})
    elif mid == 'USER':
        sess = STATE.get_session(msg.data.get('LKEY', ''))
        if sess:
            sess.theater_conn = ctx['conn']
            ctx['session'] = sess
            reply.data['NAME'] = sess.user.name if sess.user else ''
            if sess.user:
                peer = _peer_ip(ctx['conn'])
                if peer:
                    sess.user.known_ips.add(peer)
                    STATE.save_database()
        else:
            reply.data['NAME'] = ''
    elif mid == 'LLST':
        reply.data['NUM-LOBBIES'] = 1
        out.append(FESLMessage('LDAT', 0, {
            'TID': msg.data.get('TID', ''), 'FAVORITE-GAMES': 0,
            'FAVORITE-PLAYERS': 0, 'LID': 257, 'LOCALE': 'en_US',
            'MAX-GAMES': 10000, 'NAME': 'mercs2PC01',
            'NUM-GAMES': len(STATE.games), 'PASSING': len(STATE.games)}))
    elif mid == 'GDAT':
        game = None
        gid_val = _int(msg.data.get('GID', 0))
        if gid_val > 0:
            game = STATE.games.get(gid_val)
        elif 'USER' in msg.data:
            game = STATE.find_game(msg.data['USER'])
        # Play Now path: after pnow hands the client the pool, its quickmatch
        # GDAT arrives with GID=0/LID=0 and no USER. The old lookup missed and
        # returned empty, dead-ending the join. Treat it as "give me a game"
        # and serve the best available lobby so the client can EGAM into it.
        if game is None and 'USER' not in msg.data:
            sess = ctx['session']
            exclude = sess.user if sess else None
            flt = sess.pnow_filters if sess else None
            game = _pick_available_game(exclude, flt)
            if game is not None and DEBUG_PACKETS:
                print "      [*] PLAYNOW: GDAT GID=0 (filters={0}) -> serving lobby {1}".format(
                    flt, game.id)
        if game and game.host:
            reply.data.update({
                'LID': game.lid, 'GID': game.id, 'TYPE': 'G', 'N': 'hostname',
                'I': game.ipEx[0], 'P': game.ipEx[1], 'PL': 'PC', 'V': '1.0',
                'HN': game.host.name, 'HU': game.host.id, 'J': 'O', 'JP': 0,
                'AP': len(game.players), 'MP': game.slots, 'PW': 0, 'QP': 0,
                'INT-IP': game.ipIn[0], 'INT-PORT': game.ipIn[1]
            })
            # game.info already carries the host's B-version (and all other
            # broadcast fields) straight from CGAM/UGAM, so the lobby advertises
            # its true version. With every client patched to the same value this
            # just matches -- no masking needed.
            reply.data.update(game.info)

            out.append(FESLMessage('GDET', 0, {'TID': msg.data.get('TID', ''), 'LID': game.lid, 'GID': game.id, 'UGID': game.uid}))
            out.append(FESLMessage('PDAT', 0, {'TID': msg.data.get('TID', ''), 'GID': game.id, 'LID': game.lid, 'NAME': game.host.name, 'UID': game.host.id, 'PID': 1}))
        else:
            # No game matched -- find-a-friend miss, stale GID, empty pool, or a
            # host-less lobby. Reply on the TID anyway (bare GDAT, no GID/game
            # fields) so the client treats it as "not found" and shows an error,
            # instead of locking on the search dialog waiting for a response that
            # never comes. (Previously returning nothing caused the hang.)
            if DEBUG_PACKETS:
                print "      [*] GDAT: no match (USER={0!r} GID={1}) -> not-found reply".format(
                    msg.data.get('USER'), gid_val)
            out = [reply]
    elif mid == 'CGAM':
        out = _handle_create_game(ctx, msg)
    elif mid == 'EGAM':
        out = _handle_enter_game(ctx, msg)
    elif mid == 'EGRS':
        out = _handle_enter_game_response(ctx, msg)
    elif mid == 'ECNL':
        reply.data['GID'] = msg.data.get('GID')
        reply.data['LID'] = msg.data.get('LID')
        g = _game_by_gid(msg.data.get('GID'))
        if g:
            sess = ctx['session']
            u = sess.user if sess else None
            # Remove the actual canceller, not "the last player in the list".
            with STATE.lock:
                if u is not None and u in g.players:
                    g.players.remove(u)
    elif mid == 'RGAM':
        gid = _gid_int(msg.data.get('GID'))
        with STATE.lock:
            removed = STATE.games.pop(gid, None) is not None
        if removed and DEBUG_PACKETS:
            print "    [*] THEATER: Game {0} removed (Host closed session)".format(gid)
    elif mid == 'PENT':
        reply.data['PID'] = msg.data.get('PID')
    elif mid == 'PLVT':
        out = []
    elif mid == 'UBRA':
        pass
    elif mid == 'UGAM':
        # Host pushed updated game settings (mission, friendly fire, money,
        # ...). Merge the broadcast (B-*) fields into the lobby so custom
        # search and GDAT reflect the LIVE state rather than the frozen
        # create-time values -- without this, e.g. a mission filter never
        # matches because B-U-Mission was empty at CGAM. No reply expected.
        g = _game_by_gid(msg.data.get('GID'))
        if g:
            for k, v in msg.data.items():
                if k.startswith('B-'):
                    g.info[k] = v
        out = []
    else:
        if DEBUG_PACKETS:
            print "    [!] UNHANDLED theater id={0}".format(mid)

    return out

# ----------------------------------------------------------------------------
# Connection loops
# ----------------------------------------------------------------------------
def handle_fesl_client(conn, addr):
    ep = "{0}:{1}".format(*addr)
    session = Session(conn, addr[0])
    buf = ''
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                break
            buf += data
            messages, buf = extract_messages(buf)
            for msg in messages:
                _log_msg("FESL  IN ", ep, msg, 'TXN')
                for reply in handle_fesl_message(session, msg):
                    _log_msg("FESL  OUT", ep, reply, 'TXN')
                    send_msg(conn, reply)
    except Exception as e:
        pass
    finally:
        session.stop_heartbeat()
        conn.close()
        _drop_conn_lock(conn)
        print "[-] FESL session closed with {0}".format(addr)

def handle_theater_client(conn, addr):
    ep = "{0}:{1}".format(*addr)
    ctx = {'conn': conn, 'session': None}
    buf = ''
    try:
        while True:
            data = conn.recv(4096)
            if not data:
                break
            buf += data
            messages, buf = extract_messages(buf)
            for msg in messages:
                _log_msg("THTR  IN ", ep, msg, 'TID')
                for reply in handle_theater_message(ctx, msg):
                    _log_msg("THTR  OUT", ep, reply, 'TID')
                    send_msg(conn, reply)
    except Exception as e:
        pass
    finally:
        conn.close()
        _drop_conn_lock(conn)
        # Remove *this* player from their lobby. A host leaving ends the
        # session (the lobby is torn down); a joiner leaving just frees their
        # slot and keeps the lobby for the host.
        sess = ctx['session']
        if sess and sess.user:
            note = _drop_user_from_lobby(sess.user)
            if note:
                print "[*] CLEANUP: {0}".format(note)
        print "[-] THEATER session closed with {0}".format(addr)

# ----------------------------------------------------------------------------
# Servers
# ----------------------------------------------------------------------------
def _fesl_accept(client, addr):
    # Do the (blocking) TLS handshake HERE in the per-connection worker, not in
    # the accept loop -- a client that connects but stalls the handshake must
    # not be able to freeze new logins. The timeout caps how long a half-open
    # handshake can tie up this one thread.
    try:
        client.settimeout(20.0)
        secure = ssl.wrap_socket(
            client, server_side=True,
            certfile=CERT_FILE, keyfile=KEY_FILE,
            ssl_version=ssl.PROTOCOL_SSLv3,
            ciphers='RC4-SHA:RC4-MD5')
    except Exception as e:
        print "[!] HANDSHAKE FAILED {0}: {1}".format(addr, e)
        try:
            client.close()
        except Exception:
            pass
        return
    try:
        secure.settimeout(None)   # blocking for the session; heartbeat keeps it warm
    except Exception:
        pass
    print "\n[+] FESL: SSL session up with {0}".format(addr)
    handle_fesl_client(secure, addr)

def fesl_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', FESL_PORT))
    s.listen(5)
    print "[*] FESL listening on TCP {0} (SSLv3/RC4)".format(FESL_PORT)

    while True:
        try:
            client, addr = s.accept()
        except Exception as e:
            print "[!] FESL accept error: {0}".format(e)
            continue
        t = threading.Thread(target=_fesl_accept, args=(client, addr))
        t.daemon = True
        t.start()

def theater_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', THEATER_PORT))
    s.listen(5)
    print "[*] THEATER listening on TCP {0} (plaintext)".format(THEATER_PORT)
    while True:
        client, addr = s.accept()
        print "\n[+] THEATER: TCP session from {0}".format(addr)
        t = threading.Thread(target=handle_theater_client, args=(client, addr))
        t.daemon = True
        t.start()

def gamespy_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(('0.0.0.0', GAMESPY_PORT))
    print "[*] GameSpy availability responder on UDP {0}".format(GAMESPY_PORT)
    while True:
        data, addr = s.recvfrom(1024)
        if len(data) > 5:
            response = struct.pack('<L', GAMESPY_MAGIC) + b'\x00\x00\x00'
            s.sendto(response, addr)

if __name__ == "__main__":
    print "======================================================="
    print "[*] Mercenaries 2 Interceptor (FESL + Theater + GameSpy)"
    print "[*] Advertised Public IP: {0}".format(SERVER_IP)
    print "[*] Logging to: {0}".format(LOG_PATH)
    print "======================================================="

    for fn in (gamespy_server, theater_server):
        th = threading.Thread(target=fn)
        th.daemon = True
        th.start()

    fesl_server()