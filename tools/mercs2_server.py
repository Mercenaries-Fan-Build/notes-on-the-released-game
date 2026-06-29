#!/usr/bin/env python3
# Faithful Python-3 port of loganw234/Mercenaries2 server.py (FESL + Theater +
# GameSpy + UDP relay). The ONLY behavioural change vs the original: FESL is
# served as PLAINTEXT on FESL_PLAIN_PORT and fronted by our tlsterm (which does
# the SSLv3/RC4 the original did inline). Logic is otherwise verbatim so the
# game walks the exact proven login flow.
import os, base64, socket, struct, random, threading, time

SERVER_IP      = "127.0.0.1"
FESL_PLAIN_PORT = 28710          # plaintext; tlsterm:18710 forwards here
THEATER_PORT   = 18715           # plaintext TCP (advertised in Hello)
GAMESPY_PORT   = 27900           # UDP availability responder
MESSENGER_PORT = 13505           # advertised only

CUR_TIME = '"Jan-01-2012 12:00:00 UTC"'
GAMESPY_MAGIC = 654846
DEBUG_PACKETS = True
SEND_LOCK = threading.Lock()

RELAY_PORT_MIN = 10000
RELAY_PORT_MAX = 10100
AVAILABLE_PORTS = list(range(RELAY_PORT_MIN, RELAY_PORT_MAX + 1))
PORT_LOCK = threading.Lock()


def allocate_relay_ports():
    with PORT_LOCK:
        if len(AVAILABLE_PORTS) >= 2:
            return AVAILABLE_PORTS.pop(0), AVAILABLE_PORTS.pop(0)
        return None, None


def free_relay_ports(p1, p2):
    with PORT_LOCK:
        AVAILABLE_PORTS.extend([p1, p2])


def threaded_udp_relay(host_port, joiner_port, game_id, expected_ips):
    sock_host = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock_joiner = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock_host.bind(('0.0.0.0', host_port))
        sock_joiner.bind(('0.0.0.0', joiner_port))
    except Exception as e:
        print("[!] RELAY: bind failed {0}/{1} (Game {2}): {3}".format(host_port, joiner_port, game_id, e))
        sock_host.close(); sock_joiner.close(); free_relay_ports(host_port, joiner_port); return

    endpoints = {'host': None, 'joiner': None}
    running = [True]; last_active = [time.time()]

    def relay(src_sock, dst_sock, src_key, dst_key):
        src_sock.settimeout(1.0)
        while running[0]:
            try:
                data, addr = src_sock.recvfrom(2048)
            except socket.timeout:
                continue
            except Exception:
                continue
            locked = endpoints[src_key]
            if locked is None:
                expected_ip = expected_ips.get(src_key)
                if expected_ip is None or addr[0] != expected_ip:
                    continue
                endpoints[src_key] = addr
                print("[*] RELAY: locked {0} -> {1} (Game {2})".format(src_key, addr, game_id))
            elif addr != locked:
                continue
            last_active[0] = time.time()
            dst = endpoints[dst_key]
            if dst:
                try:
                    dst_sock.sendto(data, dst)
                except Exception:
                    pass

    for args in (('host', 'joiner'), ('joiner', 'host')):
        sk = (sock_host, sock_joiner) if args[0] == 'host' else (sock_joiner, sock_host)
        threading.Thread(target=relay, args=(sk[0], sk[1], args[0], args[1]), daemon=True).start()

    while game_id in STATE.games:
        if time.time() - last_active[0] > 600.0:
            if game_id in STATE.games:
                del STATE.games[game_id]
            break
        time.sleep(1)
    running[0] = False
    sock_host.close(); sock_joiner.close(); free_relay_ports(host_port, joiner_port)


# --- wire format ---
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
        body_b = body.encode('latin-1')
        length = len(body_b) + 12
        tid = self.type_id.encode('latin-1')[:4].ljust(4, b' ')
        return struct.pack('!4sII', tid, self.flags, length) + body_b

    @staticmethod
    def parse(raw):
        type_id, flags, length = struct.unpack('!4sII', raw[:12])
        body = raw[12:length].strip(b'\x00\n')
        msg = FESLMessage(type_id.decode('latin-1'), flags)
        if body:
            for line in body.decode('latin-1').split('\n'):
                if '=' in line:
                    k, v = line.split('=', 1)
                    msg.data[k] = _unquote(v)
        return msg

def extract_messages(buf):
    msgs = []
    while len(buf) >= 12:
        _, _, length = struct.unpack('!4sII', buf[:12])
        if length < 12 or length > 0x10000:
            return msgs, b''
        if len(buf) < length:
            break
        msgs.append(FESLMessage.parse(buf[:length]))
        buf = buf[length:]
    return msgs, buf

def send_msg(conn, msg):
    with SEND_LOCK:
        try:
            conn.sendall(msg.serialize())
        except Exception:
            pass

def _log_msg(direction, ep, msg, key):
    ident = msg.data.get(key, '')
    print("{0} {1} id={2} {3}={4}".format(direction, ep, msg.type_id, key, ident))
    if DEBUG_PACKETS and msg.data:
        print("      PAYLOAD: {0}".format(msg.data))


# --- state & accounts ---
class User(object):
    def __init__(self, uid, name):
        self.id = uid; self.name = name; self.session = None
        self.game_version = None; self.known_ips = set()
        self.stats = {'logins': 0, 'games_hosted': 0, 'games_joined': 0}

class EnterGameRequest(object):
    def __init__(self):
        self.id = -1634156166; self.pid = 0; self.user = None
        self.ipIn = (None, None); self.ipEx = (None, None)

class Game(object):
    def __init__(self):
        self.id = 0; self.lid = 257; self.host = None; self.players = []
        self.requests = {}; self.ekey = 'T1LZMJuD6PVPPjQsjv4r6Q=='
        self.secret = ('kYcQzhZU7rWVNTl49aTFjT2bDDOrZ/ATI+pBcc5h5PQ'
                       'fQi4cSf6rNDXlSGuaIEfdLKsYg6CjNtvugPm11NfuBg==')
        self.uid = '3cfb83c0-d98a-4ecc-ad06-3242c12bd070'
        self.ipEx = (None, None); self.ipIn = (None, None); self.slots = 0
        self.info = {}; self.relay_ports = (None, None); self.relay_expected_ips = None

class Session(object):
    def __init__(self, fesl_conn=None, client_ip="Unknown"):
        self.user = None; self.lkey = None; self.fesl_conn = fesl_conn
        self.theater_conn = None; self.client_ip = client_ip
        self._stop = threading.Event(); self._hb = None

    def start_heartbeat(self):
        if self._hb is None:
            self._hb = threading.Thread(target=self._loop, daemon=True); self._hb.start()

    def stop_heartbeat(self):
        self._stop.set()

    def _loop(self):
        last = time.time()
        while not self._stop.is_set():
            time.sleep(1)
            if time.time() - last >= 120:
                last = time.time()
                if self.fesl_conn:
                    try:
                        send_msg(self.fesl_conn, FESLMessage('fsys', 0, {'TXN': 'Ping'}))
                        send_msg(self.fesl_conn, FESLMessage('fsys', 0x80000000,
                                 {'TXN': 'MemCheck', 'salt': random.getrandbits(32),
                                  'type': 0, 'memcheck': []}))
                    except Exception:
                        self.stop_heartbeat()

class TheaterState(object):
    def __init__(self):
        self.users = {}; self.sessions = {}; self.games = {}
        self.last_user_id = 1000; self.last_game_id = 1000
        self.ip_versions = {}; self.lock = threading.Lock()

    def create_user(self, name):
        with self.lock:
            self.last_user_id += 1
            u = User(self.last_user_id, name); self.users[name] = u; return u

    def get_user(self, name):
        return self.users.get(name)

    def get_or_create(self, name):
        return self.get_user(name) or self.create_user(name)

    def register_session(self, lkey, s):
        with self.lock:
            self.sessions[lkey] = s

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
            self.last_game_id += 1; return self.last_game_id

STATE = TheaterState()
PERSONAS = []

def gen_lkey():
    return base64.urlsafe_b64encode(os.urandom(20)).rstrip(b'=').decode('ascii') + '.'

def _entitlement_block():
    return [{'gameFeatureId': 6014, 'status': 0, 'message': '',
             'entitlementExpirationDate': '', 'entitlementExpirationDays': -1}]

def to_ea_mapping(d):
    out = dict(('{%s}' % k, v) for k, v in d.items())
    out['{}'] = len(out)
    return out

_TELEMETRY_RAW = (b'159.153.244.83,9988,enFI,'
    b'^\xf2\xf0\xbd\xaf\x88\xf8\xca\x94\x96\x9f\x96\xdd\xcd\xc6\x9b\xe9\xad\xd7'
    b'\xa8\x8a\xb6\xec\xda\xb0\xec\xea\xcd\xe3\xc2\x84\x8c\x98\xb1\xc4\x99\x9b'
    b'\xa6\xec\x8c\x9b\xb9\xc6\x89\xe3\xc2\x84\x8c\x98\xb0\xe0\xc0\x81\x83\x86'
    b'\x8c\x98\xe1\xc6\xd1\xa9\x86\xa6\x8d\xb1\xac\x8a\x85\xba\x94\xa8\xd3\xa2'
    b'\xd3\xde\x8c\xf2\xb4\xc8\xd4\xa0\xb3\xd8\xc4\x91\xb3\x86\xcc\x99\xb8\xe2'
    b'\xc8\xb1\x83\x87\xcb\xb2\xee\x8c\xa5\x82\n')


def handle_fesl_message(session, msg):
    txn = msg.data.get('TXN', '')
    reply = FESLMessage(msg.type_id, 0x80000000 | (msg.flags & 0xFF))
    reply.data['TXN'] = txn
    out = [reply]

    if msg.type_id == 'fsys':
        if txn == 'Hello':
            reply.data.update({
                'activityTimeoutSecs': 0, 'curTime': CUR_TIME,
                'messengerIp': SERVER_IP, 'messengerPort': MESSENGER_PORT,
                'theaterIp': SERVER_IP, 'theaterPort': THEATER_PORT,
                'domainPartition.domain': 'eagames', 'domainPartition.subDomain': 'MERCS2',
            })
            out.append(FESLMessage('fsys', 0x80000000,
                       {'TXN': 'MemCheck', 'salt': random.getrandbits(32),
                        'type': 0, 'memcheck': []}))
            session.start_heartbeat()
        elif txn in ('MemCheck', 'Goodbye', 'Ping'):
            out = []
        elif txn == 'GetPingSites':
            reply.data.update({'minPingSitesToPing': 0, 'pingSite': [
                {'addr': SERVER_IP, 'name': 'eu-ip', 'type': 0},
                {'addr': SERVER_IP, 'name': 'ec-ip', 'type': 0},
                {'addr': SERVER_IP, 'name': 'wc-ip', 'type': 0}]})
        else:
            if DEBUG_PACKETS: print("[!] UNHANDLED fsys TXN={0}".format(txn))

    elif msg.type_id == 'acct':
        if txn in ('NuLogin', 'Login'):
            name = msg.data.get('name', 'Player') if txn == 'Login' else msg.data.get('nuid', 'Player@ea.com')
            session.user = STATE.get_or_create(name); session.user.session = session
            session.lkey = gen_lkey(); STATE.register_session(session.lkey, session)
            session.user.known_ips.add(session.client_ip); session.user.stats['logins'] += 1
            if DEBUG_PACKETS:
                print("      [*] ACCOUNT: {0} logged in (logins={1})".format(session.user.name, session.user.stats['logins']))
            reply.data.update({'displayName': session.user.name, 'userId': session.user.id,
                               'profileId': session.user.id, 'lkey': session.lkey,
                               'entitledGameFeatureWrappers': _entitlement_block()})
        elif txn == 'NuGetPersonas':
            reply.data['personas'] = list(PERSONAS)
        elif txn == 'NuAddPersona':
            PERSONAS.append(msg.data.get('name', ''))
        elif txn == 'NuLoginPersona':
            name = msg.data.get('name', 'Player')
            session.user = STATE.get_or_create(name); session.user.session = session
            session.lkey = gen_lkey(); STATE.register_session(session.lkey, session)
            reply.data['lkey'] = session.lkey; reply.data['profileId'] = session.user.id
            reply.data['userId'] = session.user.id
        elif txn == 'NuEntitleGame':
            out = []
        elif txn == 'GetTelemetryToken':
            reply.data.update({'enabled': 'CA,MX,PR,US,VI', 'disabled': '', 'filters': '',
                               'telemetryToken': base64.b64encode(_TELEMETRY_RAW).decode('ascii')})
        elif txn == 'GameSpyPreAuth':
            reply.data['challenge'] = 'gnbzlxhv'
            reply.data['ticket'] = ('CCUBnHUPERml+OVgejfpuXqQS9VmzKBnBalrwEnQ8HBNvxOl/8qpukAzGCJ1HzT'
                                    'undOT8w6gFXNtNk4bDJnd0xtgw==')
            out.append(FESLMessage('fsys', 0, {'TXN': 'Ping'}))
        elif txn == 'LookupUserInfo':
            user = STATE.find_user(msg.data.get('userInfo.0.userId'))
            if user:
                reply.data['userInfo'] = [{'userName': user.name, 'userId': user.id, 'namespace': 'MAIN'}]
        else:
            if DEBUG_PACKETS: print("[!] UNHANDLED acct TXN={0}".format(txn))

    elif msg.type_id == 'subs':
        if txn == 'GetEntitlementByBundle':
            reply.data.update({'pricingOptionId': 'REG-PC-MERCENARIES2-UNLOCK-1',
                'name': '"Mercenaries 2 UNLOCK 1 PC"', 'description': '"Mercenaries 2 UNLOCK 1 PC"',
                'type': 1, 'entitlementStatus': 0, 'entitlementStatusDesc': 'ACTIVE',
                'entitlementSuspendDate': ''})
        else:
            if DEBUG_PACKETS: print("[!] UNHANDLED subs TXN={0}".format(txn))

    elif msg.type_id == 'pnow':
        if txn == 'Start':
            gid = 605
            partition = msg.data.get('partition.partition', '/eagames/MERCS2')
            reply.data['id.id'] = gid; reply.data['id.partition'] = partition
            client_hash = msg.data.get('players.0.props.{filter-version}')
            if client_hash:
                STATE.ip_versions[session.client_ip] = client_hash
                if session.user:
                    session.user.game_version = client_hash
            active = [g.id for g in STATE.games.values()]
            out.append(FESLMessage('pnow', 0x80000000, {
                'TXN': 'Status', 'id.id': gid, 'id.partition': partition,
                'sessionState': 'COMPLETE',
                'props': to_ea_mapping({'availableServerCount': len(active),
                                        'games': active, 'resultType': 'LIST'})}))

    elif msg.type_id == 'rank':
        if txn == 'GetRankedStats':
            name = session.user.name if session.user else 'Player'
            reply.data['stats'] = [{'key': 'vz', 'rank': 4390, 'text': name, 'value': '0.0000'}]
    else:
        if DEBUG_PACKETS: print("[!] UNHANDLED id={0} TXN={1}".format(msg.type_id, txn))

    return out


# --- theater ---
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
        return SERVER_IP

def _handle_create_game(ctx, msg):
    sess = ctx['session']; g = Game(); g.id = STATE.generate_game_id()
    g.host = sess.user if sess else None
    g.ipEx = (_peer_ip(ctx['conn']), msg.data.get('PORT'))
    g.ipIn = (msg.data.get('INT-IP'), msg.data.get('INT-PORT'))
    g.slots = msg.data.get('MAX-PLAYERS')
    g.info = dict((k, v) for k, v in msg.data.items() if k.startswith('B-'))
    STATE.games[g.id] = g
    if g.host:
        g.host.stats['games_hosted'] += 1
    g.relay_ports = allocate_relay_ports()
    if g.relay_ports[0] and g.relay_ports[1]:
        g.relay_expected_ips = {'host': g.ipEx[0], 'joiner': None}
        threading.Thread(target=threaded_udp_relay,
                         args=(g.relay_ports[0], g.relay_ports[1], g.id, g.relay_expected_ips),
                         daemon=True).start()
    return [_theater_reply(msg, {'EKEY': g.ekey, 'GID': g.id, 'J': 0, 'JOIN': 0, 'LID': g.lid,
                                 'MAX-PLAYERS': g.slots, 'SECRET': g.secret, 'UGID': g.uid})]

def _handle_enter_game(ctx, msg):
    joiner = ctx['session']
    game = STATE.games.get(int(msg.data['GID'])) if 'GID' in msg.data else STATE.find_game(msg.data.get('USER'))
    if not game:
        return [_theater_reply(msg, {})]
    rq = EnterGameRequest(); rq.pid = min(len(game.players) + 1, 2)
    rq.user = joiner.user if joiner else None
    rq.ipIn = (msg.data.get('R-INT-IP'), int(msg.data.get('R-INT-PORT', 0)))
    rq.ipEx = (_peer_ip(ctx['conn']), msg.data.get('PORT'))
    game.requests[rq.pid] = rq
    if game.relay_expected_ips is not None:
        game.relay_expected_ips['joiner'] = rq.ipEx[0]
    reply = _theater_reply(msg, {'GID': game.id, 'LID': game.lid})
    host_port = game.relay_ports[0] if game.relay_ports[0] else rq.ipEx[1]
    rdict = {'PTYPE': 'P', 'GID': game.id, 'IP': SERVER_IP, 'PORT': host_port, 'LID': game.lid,
             'NAME': rq.user.name, 'UID': rq.user.id, 'PID': rq.pid, 'R-INT-IP': rq.ipIn[0],
             'R-INT-PORT': rq.ipIn[1], 'TICKET': rq.id}
    if game.host is not rq.user:
        rdict.update({'R-USER': game.host.name, 'R-U-USERID': game.host.id})
    host_sess = game.host.session if game.host else None
    if host_sess and host_sess.theater_conn:
        send_msg(host_sess.theater_conn, FESLMessage('EGRQ', 0, rdict))
    return [reply]

def _handle_enter_game_response(ctx, msg):
    reply = _theater_reply(msg, {})
    game = STATE.games.get(int(msg.data.get('GID', -1)))
    if not game:
        return [reply]
    pid = int(msg.data.get('PID', 0)); rq = game.requests.get(pid)
    if not rq:
        return [reply]
    game.players.append(rq.user)
    if rq.user:
        rq.user.stats['games_joined'] += 1
    joiner_port = game.relay_ports[1] if game.relay_ports[1] else game.ipEx[1]
    joiner_sess = rq.user.session if rq.user else None
    if joiner_sess and joiner_sess.theater_conn:
        send_msg(joiner_sess.theater_conn, FESLMessage('EGEG', 0, {
            'LID': game.lid, 'GID': game.id, 'UGID': game.uid, 'HUID': game.host.id,
            'I': SERVER_IP, 'P': joiner_port, 'INT-IP': game.ipIn[0], 'INT-PORT': game.ipIn[1],
            'PL': 'pc', 'PID': pid, 'EKEY': game.ekey, 'TICKET': rq.id}))
    return [reply]

def handle_theater_message(ctx, msg):
    mid = msg.type_id; reply = _theater_reply(msg); out = [reply]
    if mid == 'CONN':
        reply.data.update({'TIME': int(time.time()), 'activityTimeoutSecs': 86400, 'PROT': 2})
    elif mid == 'USER':
        sess = STATE.get_session(msg.data.get('LKEY', ''))
        if sess:
            sess.theater_conn = ctx['conn']; ctx['session'] = sess
            reply.data['NAME'] = sess.user.name if sess.user else ''
            if sess.user:
                sess.user.known_ips.add(_peer_ip(ctx['conn']))
        else:
            reply.data['NAME'] = ''
    elif mid == 'LLST':
        reply.data['NUM-LOBBIES'] = 1
        out.append(FESLMessage('LDAT', 0, {'TID': msg.data.get('TID', ''), 'FAVORITE-GAMES': 0,
            'FAVORITE-PLAYERS': 0, 'LID': 257, 'LOCALE': 'en_US', 'MAX-GAMES': 10000,
            'NAME': 'mercs2PC01', 'NUM-GAMES': len(STATE.games), 'PASSING': len(STATE.games)}))
    elif mid == 'GDAT':
        game = STATE.games.get(int(msg.data['GID'])) if 'GID' in msg.data else (
            STATE.find_game(msg.data['USER']) if 'USER' in msg.data else None)
        if game:
            reply.data.update({'LID': game.lid, 'GID': game.id, 'TYPE': 'G', 'N': 'hostname',
                'I': game.ipEx[0], 'P': game.ipEx[1], 'PL': 'PC', 'V': '1.0', 'HN': game.host.name,
                'HU': game.host.id, 'J': 'O', 'JP': 0, 'AP': len(game.players), 'MP': game.slots,
                'PW': 0, 'QP': 0, 'INT-IP': game.ipIn[0], 'INT-PORT': game.ipIn[1]})
            reply.data.update(game.info)
            out.append(FESLMessage('GDET', 0, {'TID': msg.data.get('TID', ''), 'LID': game.lid, 'GID': game.id, 'UGID': game.uid}))
            out.append(FESLMessage('PDAT', 0, {'TID': msg.data.get('TID', ''), 'GID': game.id, 'LID': game.lid, 'NAME': game.host.name, 'UID': game.host.id, 'PID': 1}))
        else:
            out = []
    elif mid == 'CGAM':
        out = _handle_create_game(ctx, msg)
    elif mid == 'EGAM':
        out = _handle_enter_game(ctx, msg)
    elif mid == 'EGRS':
        out = _handle_enter_game_response(ctx, msg)
    elif mid == 'ECNL':
        reply.data['GID'] = msg.data.get('GID'); reply.data['LID'] = msg.data.get('LID')
        g = STATE.games.get(int(msg.data.get('GID', -1)))
        if g and g.players:
            g.players.pop()
    elif mid == 'RGAM':
        gid = int(msg.data.get('GID', -1))
        if gid in STATE.games:
            del STATE.games[gid]
    elif mid == 'PENT':
        reply.data['PID'] = msg.data.get('PID')
    elif mid in ('PLVT', 'UGAM'):
        out = []
    elif mid == 'UBRA':
        pass
    else:
        if DEBUG_PACKETS: print("    [!] UNHANDLED theater id={0}".format(mid))
    return out


# --- connection loops ---
def handle_fesl_client(conn, addr):
    ep = "{0}:{1}".format(*addr); session = Session(conn, addr[0]); buf = b''
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
    except Exception:
        pass
    finally:
        session.stop_heartbeat(); conn.close()
        print("[-] FESL session closed {0}".format(addr))

def handle_theater_client(conn, addr):
    ep = "{0}:{1}".format(*addr); ctx = {'conn': conn, 'session': None}; buf = b''
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
    except Exception:
        pass
    finally:
        conn.close()
        print("[-] THEATER session closed {0}".format(addr))


def fesl_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('127.0.0.1', FESL_PLAIN_PORT)); s.listen(5)
    print("[*] FESL (plaintext behind tlsterm) on {0}".format(FESL_PLAIN_PORT))
    while True:
        c, addr = s.accept()
        print("[+] FESL conn {0}".format(addr))
        threading.Thread(target=handle_fesl_client, args=(c, addr), daemon=True).start()

def theater_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('0.0.0.0', THEATER_PORT)); s.listen(5)
    print("[*] THEATER on {0} (plaintext)".format(THEATER_PORT))
    while True:
        c, addr = s.accept()
        print("[+] THEATER conn {0}".format(addr))
        threading.Thread(target=handle_theater_client, args=(c, addr), daemon=True).start()

def gamespy_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.bind(('0.0.0.0', GAMESPY_PORT))
    print("[*] GameSpy availability on UDP {0}".format(GAMESPY_PORT))
    while True:
        data, addr = s.recvfrom(1024)
        if len(data) > 5:
            s.sendto(struct.pack('<L', GAMESPY_MAGIC) + b'\x00\x00\x00', addr)


if __name__ == "__main__":
    print("=== Mercenaries 2 server (py3 port of loganw234/Mercenaries2) ===")
    for fn in (gamespy_server, theater_server):
        threading.Thread(target=fn, daemon=True).start()
    fesl_server()
