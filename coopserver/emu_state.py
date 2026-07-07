"""Shared FESL/Theater emulator state — accounts, sessions, lobbies, profile DB.

Python-3 port of the hardened community server (`updated_mercs_server.py`):
per-account personas, race-safe lobby deletes, debounced JSON profile
persistence, and the relay-port pool. The async connection handlers
(fesl_handler.py) own the I/O; this module owns the state.
"""
from __future__ import annotations

import base64
import json
import os
import threading
import time
import uuid

from config import config


# --- relay-port pool ------------------------------------------------------
RELAY_PORT_MIN = 10000
RELAY_PORT_MAX = 10100
_AVAILABLE_PORTS = list(range(RELAY_PORT_MIN, RELAY_PORT_MAX + 1))
_PORT_LOCK = threading.Lock()


def allocate_relay_ports():
    with _PORT_LOCK:
        if len(_AVAILABLE_PORTS) >= 2:
            return _AVAILABLE_PORTS.pop(0), _AVAILABLE_PORTS.pop(0)
        return None, None


def free_relay_ports(p1, p2):
    with _PORT_LOCK:
        _AVAILABLE_PORTS.extend([p1, p2])


# --- small parsing helpers ------------------------------------------------

def _int(v, default=0):
    try:
        return int(v)
    except (TypeError, ValueError):
        return default


def gid_int(v):
    try:
        return int(v)
    except (TypeError, ValueError):
        return None


def gen_lkey() -> str:
    return base64.urlsafe_b64encode(os.urandom(20)).rstrip(b"=").decode("ascii") + "."


def entitlement_block() -> list:
    return [{"gameFeatureId": 6014, "status": 0, "message": "",
             "entitlementExpirationDate": "", "entitlementExpirationDays": -1}]


def to_ea_mapping(d: dict) -> dict:
    out = {"{%s}" % k: v for k, v in d.items()}
    out["{}"] = len(out)
    return out


# --- account / session / lobby models -------------------------------------

class User:
    def __init__(self, uid, name):
        self.id = uid
        self.name = name
        self.session = None
        self.known_ips: set[str] = set()
        self.personas: list[str] = []      # per-account (not a shared global)
        self.stats = {"logins": 0, "games_hosted": 0, "games_joined": 0}

    def to_dict(self):
        return {"id": self.id, "name": self.name,
                "known_ips": list(self.known_ips), "personas": list(self.personas),
                "stats": dict(self.stats)}

    def load_from_dict(self, data):
        self.id = data.get("id", self.id)
        self.known_ips = set(data.get("known_ips", []))
        self.personas = list(data.get("personas", []))
        self.stats.update(data.get("stats", {}))


class EnterGameRequest:
    def __init__(self):
        self.id = -1634156166
        self.pid = 0
        self.user = None
        self.ipIn = (None, None)
        self.ipEx = (None, None)


class Game:
    def __init__(self):
        self.id = 0
        self.lid = 257
        self.host = None
        self.players: list[User] = []
        self.requests: dict[int, EnterGameRequest] = {}
        self.ekey = "T1LZMJuD6PVPPjQsjv4r6Q=="
        self.secret = ("kYcQzhZU7rWVNTl49aTFjT2bDDOrZ/ATI+pBcc5h5PQ"
                       "fQi4cSf6rNDXlSGuaIEfdLKsYg6CjNtvugPm11NfuBg==")
        self.uid = str(uuid.uuid4())        # unique per lobby
        self.ipEx = (None, None)
        self.ipIn = (None, None)
        self.slots = 0
        self.info: dict[str, str] = {}
        self.relay_ports = (None, None)
        # {'host': <ip>, 'joiner': <ip or None>} — source-IP allow-list for the
        # UDP relay (blocks a port scanner from hijacking an active session).
        self.relay_expected_ips = None


class Session:
    """One authenticated player. Holds the FESL writer (for the heartbeat +
    server pushes) and, once bound via Theater USER, the Theater writer (for
    EGRQ/EGEG routing to the *other* peer)."""

    def __init__(self, client_ip="Unknown"):
        self.user = None
        self.lkey = None
        self.fesl_writer = None            # asyncio.StreamWriter
        self.theater_writer = None
        self.client_ip = client_ip
        self.pnow_filters: list = []       # last custom-search predicates
        self.heartbeat_task = None         # asyncio.Task


class TheaterState:
    def __init__(self):
        self.users: dict[str, User] = {}
        self.sessions: dict[str, Session] = {}
        self.games: dict[int, Game] = {}
        self.last_user_id = 0
        self.last_game_id = 1000
        self.lock = threading.Lock()
        self._dirty = threading.Event()
        self._db_file = config.profile_db
        self.load_database()
        saver = threading.Thread(target=self._save_loop, daemon=True)
        saver.start()

    # --- persistence (debounced background save) ---
    def load_database(self):
        if self._db_file and os.path.exists(self._db_file):
            try:
                with open(self._db_file, "r") as f:
                    data = json.load(f)
                for name, udata in data.items():
                    u = User(udata.get("id", self.last_user_id + 1), name)
                    u.load_from_dict(udata)
                    self.users[name] = u
                    self.last_user_id = max(self.last_user_id, u.id)
                print(f"[emu] loaded {len(self.users)} profiles from {self._db_file}")
            except Exception as e:  # noqa: BLE001
                print(f"[emu] WARN could not load {self._db_file}: {e}")

    def save_database(self):
        self._dirty.set()

    mark_dirty = save_database

    def _save_loop(self):
        while True:
            self._dirty.wait()
            time.sleep(2.0)      # coalesce a burst of changes
            self._dirty.clear()
            self._save_now()

    def _save_now(self):
        if not self._db_file:
            return
        with self.lock:
            try:
                data = {name: u.to_dict() for name, u in self.users.items()}
                with open(self._db_file, "w") as f:
                    json.dump(data, f, indent=4)
            except Exception as e:  # noqa: BLE001
                print(f"[emu] WARN could not save {self._db_file}: {e}")

    # --- accounts ---
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
        uid = gid_int(uid)
        if uid is None:
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

    def game_by_gid(self, v):
        gid = gid_int(v)
        return self.games.get(gid) if gid is not None else None

    def generate_game_id(self):
        with self.lock:
            self.last_game_id += 1
            return self.last_game_id


STATE = TheaterState()

# Telemetry token blob (verbatim from the community server).
TELEMETRY_RAW = (b"159.153.244.83,9988,enFI,"
    b"^\xf2\xf0\xbd\xaf\x88\xf8\xca\x94\x96\x9f\x96\xdd\xcd\xc6\x9b\xe9\xad\xd7"
    b"\xa8\x8a\xb6\xec\xda\xb0\xec\xea\xcd\xe3\xc2\x84\x8c\x98\xb1\xc4\x99\x9b"
    b"\xa6\xec\x8c\x9b\xb9\xc6\x89\xe3\xc2\x84\x8c\x98\xb0\xe0\xc0\x81\x83\x86"
    b"\x8c\x98\xe1\xc6\xd1\xa9\x86\xa6\x8d\xb1\xac\x8a\x85\xba\x94\xa8\xd3\xa2"
    b"\xd3\xde\x8c\xf2\xb4\xc8\xd4\xa0\xb3\xd8\xc4\x91\xb3\x86\xcc\x99\xb8\xe2"
    b"\xc8\xb1\x83\x87\xcb\xb2\xee\x8c\xa5\x82\n")
