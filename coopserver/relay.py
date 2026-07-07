"""UDP host<->joiner relay + GameSpy availability responder.

The relay is the actual co-op *data* path: once Theater has matched a host and
a joiner, their peer-mesh UDP traffic is bounced through a pair of server ports
so neither side needs a routable address / open NAT. Ported verbatim (logic) from
the hardened community server, including the 65535 recv buffer (a smaller buffer
silently TRUNCATES the game's multi-KB level-load datagrams -> joiner stuck on a
black screen while the host shows them connected).

Kept as plain threads (not asyncio): they only touch raw UDP sockets, never the
asyncio writers, so they coexist safely with the event loop.
"""
from __future__ import annotations

import asyncio
import socket
import struct
import threading
import time

from emu_state import STATE, free_relay_ports

RELAY_RECV_BUF = 65535
GAMESPY_MAGIC = 654846
DEBUG = True


def threaded_udp_relay(host_port, joiner_port, game_id, expected_ips):
    """Relay UDP between a lobby's host and joiner. `expected_ips` is the shared
    {'host': ip, 'joiner': ip|None} allow-list; the first packet from the
    expected source IP locks the (ip, port) tuple, and anything else is dropped."""
    sock_host = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock_joiner = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock_host.bind(("0.0.0.0", host_port))
        sock_joiner.bind(("0.0.0.0", joiner_port))
    except Exception as e:  # noqa: BLE001
        print(f"[relay] bind failed {host_port}/{joiner_port} (Game {game_id}): {e}")
        sock_host.close(); sock_joiner.close()
        free_relay_ports(host_port, joiner_port)
        return

    endpoints = {"host": None, "joiner": None}
    running = [True]
    last_active = [time.time()]
    max_seen = {"host": 0, "joiner": 0}

    def relay(src_sock, dst_sock, src_key, dst_key):
        src_sock.settimeout(1.0)
        while running[0]:
            try:
                data, addr = src_sock.recvfrom(RELAY_RECV_BUF)
            except socket.timeout:
                continue
            except Exception:
                continue
            locked = endpoints[src_key]
            if locked is None:
                expected_ip = expected_ips.get(src_key)
                if expected_ip is None or addr[0] != expected_ip:
                    continue  # not yet known / probable hijack probe -> drop
                endpoints[src_key] = addr
                print(f"[relay] locked {src_key} -> {addr} (Game {game_id})")
            elif addr != locked:
                continue      # spoofed source -> drop
            last_active[0] = time.time()
            if DEBUG and len(data) > max_seen[src_key]:
                max_seen[src_key] = len(data)
                print(f"[relay] new max {src_key}->{dst_key} datagram {len(data)}B (Game {game_id})")
            dst = endpoints[dst_key]
            if dst:
                try:
                    dst_sock.sendto(data, dst)
                except Exception:
                    pass

    threading.Thread(target=relay, args=(sock_host, sock_joiner, "host", "joiner"), daemon=True).start()
    threading.Thread(target=relay, args=(sock_joiner, sock_host, "joiner", "host"), daemon=True).start()
    print(f"[relay] ports {host_port}(host)/{joiner_port}(joiner) for Game {game_id}")

    while game_id in STATE.games:
        if time.time() - last_active[0] > 600.0:
            print(f"[relay] Game {game_id} idle-timed-out (crash/Alt-F4)")
            with STATE.lock:
                STATE.games.pop(game_id, None)
            break
        time.sleep(1)

    running[0] = False
    sock_host.close(); sock_joiner.close()
    free_relay_ports(host_port, joiner_port)
    print(f"[relay] recovered ports {host_port}/{joiner_port} (Game {game_id})")


class GameSpyResponder(asyncio.DatagramProtocol):
    """Answers the GameSpy availability check with the fixed magic so the game
    considers the master server reachable."""

    def __init__(self, port: int, sink=None) -> None:
        self.port = port
        self.transport = None
        self._sink = sink

    def connection_made(self, transport):
        self.transport = transport

    def datagram_received(self, data, addr):
        if len(data) > 5 and self.transport:
            self.transport.sendto(struct.pack("<L", GAMESPY_MAGIC) + b"\x00\x00\x00", addr)
        if self._sink is not None:
            asyncio.create_task(self._sink.emit({
                "protocol": "gamespy", "direction": "inbound",
                "peer_addr": f"{addr[0]}:{addr[1]}", "server_port": self.port,
                "body_hex": data.hex() if data else None, "body_len": len(data),
                "response_summary": f"availability magic 0x{GAMESPY_MAGIC:x}",
                "notes": "gamespy-availability",
            }))
