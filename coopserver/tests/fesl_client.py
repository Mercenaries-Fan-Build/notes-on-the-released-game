"""Tiny FESL test client — opens a TLS connection to the capture server, sends a
fsys/Hello frame and an unknown transaction, and prints the framed replies.

Usage:
    python tests/fesl_client.py [host] [port]   # default 127.0.0.1 18300
"""
from __future__ import annotations

import socket
import ssl
import struct
import sys


def frame(type4: str, msg_id: int, fields: dict[str, str]) -> bytes:
    payload = ("".join(f"{k}={v}\n" for k, v in fields.items())).encode() + b"\x00"
    return type4.encode().ljust(4) + struct.pack(">II", msg_id, 12 + len(payload)) + payload


def read_frame(sock: socket.socket):
    sock.settimeout(3)
    header = b""
    while len(header) < 12:
        try:
            chunk = sock.recv(12 - len(header))
        except (TimeoutError, socket.timeout):
            return "(no reply — expected for unhandled transactions)"
        if not chunk:
            return None
        header += chunk
    type4 = header[:4].decode(errors="replace").rstrip()
    msg_id, length = struct.unpack(">II", header[4:12])
    plen = max(0, length - 12)
    payload = b""
    while len(payload) < plen:
        chunk = sock.recv(plen - len(payload))
        if not chunk:
            break
        payload += chunk
    return type4, msg_id, payload.split(b"\x00", 1)[0].decode(errors="replace")


def main() -> None:
    host = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 18300

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    try:
        ctx.set_ciphers("ALL:@SECLEVEL=0")
    except ssl.SSLError:
        pass

    raw = socket.create_connection((host, port), timeout=10)
    sock = ctx.wrap_socket(raw, server_hostname="fesl.ea.com")

    print("-> fsys/Hello")
    sock.sendall(frame("fsys", 0xC0000001, {"TXN": "Hello", "clientString": "mercenaries2-pc",
                                            "sku": "PC", "protocolVersion": "2.0"}))
    print("<-", read_frame(sock))

    print("-> subs/GetEntitlementByBundle")
    sock.sendall(frame("subs", 0xC0000002, {"TXN": "GetEntitlementByBundle", "bundle": "MERCS2DLC"}))
    print("<-", read_frame(sock))

    print("-> zzzz/MysteryTxn (should be captured as unhandled)")
    sock.sendall(frame("zzzz", 0xC0000003, {"TXN": "MysteryTxn"}))
    print("<-", read_frame(sock))

    sock.close()


if __name__ == "__main__":
    main()
