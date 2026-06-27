"""Modkit coop / network-capture server.

A single asyncio process that emulates the EA online endpoints Mercenaries 2
reaches for and logs every request the game makes — like httpbin — covering both
the main-menu (shell.wad) and in-game (vz.wad) traffic. It listens on the EA
ports (the ASI redirector preserves the destination port and only rewrites the
IP), auto-detects the application protocol per connection, captures it, and
sends a best-effort stub reply so the handshake advances.
"""
from __future__ import annotations

import asyncio
import ssl

from config import config
from dns_handler import DNSProtocol
from fesl_handler import handle_fesl
from http_handler import handle_http
from protocol_detect import BufferedConn, classify
from raw_handler import UDPLogger, handle_raw
from sink import log, sink

HEAD_PEEK = 16
HEAD_TIMEOUT = 5.0


def _make_ssl_context() -> ssl.SSLContext | None:
    try:
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        ctx.load_cert_chain(config.cert_file, config.key_file)
        # Old game clients (OpenSSL 0.9.8d) — be maximally permissive on ciphers.
        try:
            ctx.minimum_version = ssl.TLSVersion.TLSv1
        except (ValueError, AttributeError):
            pass
        try:
            ctx.set_ciphers("ALL:@SECLEVEL=0")
        except ssl.SSLError:
            pass
        return ctx
    except Exception as exc:  # noqa: BLE001
        log(f"WARN could not load TLS cert ({exc}); TLS ports will be plaintext")
        return None


def _handler_factory(port: int):
    prefer = config.prefer_for(port)

    async def on_connect(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        peername = writer.get_extra_info("peername")
        peer = f"{peername[0]}:{peername[1]}" if peername else "?"
        try:
            try:
                head = await asyncio.wait_for(reader.read(HEAD_PEEK), timeout=HEAD_TIMEOUT)
            except asyncio.TimeoutError:
                head = b""
            kind = classify(head, prefer=prefer)
            # Always log the raw accept — this is the key diagnostic: it fires for
            # EVERY connection that reaches us, even ones we can't parse.
            log(f"ACCEPT {peer} -> :{port} kind={kind} first16={head[:16].hex() or '(none)'}")
            conn = BufferedConn(head, reader)
            conn.writer = writer  # type: ignore[attr-defined]

            if kind == "http":
                await handle_http(conn, peer, port)
            elif kind in ("fesl", "theater"):
                await handle_fesl(conn, peer, port, kind=kind)
            elif kind == "empty":
                await sink.emit({
                    "protocol": "tcp", "direction": "inbound", "peer_addr": peer,
                    "server_port": port, "body_len": 0, "notes": "connect-no-data",
                })
            else:
                await handle_raw(conn, peer, port, note=f"unclassified:{kind}")
        except (ConnectionResetError, BrokenPipeError):
            pass
        except Exception as exc:  # noqa: BLE001 — never let one peer kill the listener
            log(f"ERROR handling {peer} on :{port}: {exc!r}")
        finally:
            try:
                writer.close()
            except Exception:  # noqa: BLE001
                pass

    return on_connect


async def main() -> None:
    await sink.start()
    ctx = _make_ssl_context()
    servers = []

    for port in config.plain_ports:
        srv = await asyncio.start_server(_handler_factory(port), config.bind_host, port)
        servers.append(srv)
        log(f"listening (plain) on {config.bind_host}:{port} prefer={config.prefer_for(port)}")

    for port in config.tls_ports:
        srv = await asyncio.start_server(
            _handler_factory(port), config.bind_host, port, ssl=ctx,
        )
        servers.append(srv)
        log(f"listening (tls)   on {config.bind_host}:{port} prefer={config.prefer_for(port)}")

    loop = asyncio.get_running_loop()
    for port in config.udp_ports:
        await loop.create_datagram_endpoint(
            lambda p=port: UDPLogger(p), local_addr=(config.bind_host, port),
        )
        log(f"listening (udp)   on {config.bind_host}:{port}")

    if config.dns_port:
        await loop.create_datagram_endpoint(
            lambda: DNSProtocol(config.dns_port, config.dns_resolve_ip),
            local_addr=(config.bind_host, config.dns_port),
        )
        log(f"listening (dns)   on {config.bind_host}:{config.dns_port} "
            f"-> all names resolve to {config.dns_resolve_ip}")

    log("coopserver up — waiting for the game to phone home")
    # TCP servers are already accepting (start_server), and the UDP/DNS endpoints
    # run in the background. Block forever regardless of which listeners exist
    # (gather over an empty server list would otherwise return and exit).
    await asyncio.Event().wait()


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
