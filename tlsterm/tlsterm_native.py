"""Native-Windows tlsterm: DUAL-MODE TLS terminator for Mercenaries 2's FESL client.

Terminates *both* legs the co-op stack can present, auto-detected per connection
by peeking the ClientHello's record version (never consumed — MSG_PEEK):

  * SSLv3 / RC4  (record version 03 00) — the stock game's statically-linked
    OpenSSL 0.9.8d client. Terminated with pure-Python tlslite-ng against the
    genuine EA `fesl.cer` (negotiates TLS_RSA_WITH_RC4_128_SHA, the game's offer).
    This is the path the un-modified retail exe uses.

  * Modern TLS 1.2 / 1.3  (record version 03 01+) — the SSL_METHOD-detour shim
    (networking_code_map.md §7.7) that replaces the game's OpenSSL client API and
    speaks a current TLS stack (rustls / SChannel / OpenSSL-3) with an
    accept-self-signed / TOFU policy. Terminated with stdlib `ssl` against a
    self-signed cert (auto-generated on first run). No CA pin, no EA cert.

Both legs decrypt to the SAME plaintext FESL upstream, and both emit a `tls`
capture event to the Modkit webapp so the handshake shows up in the inspector.

  game --SSLv3/RC4----> tlsterm(:18710) --plaintext--> upstream(:UPSTREAM)
  shim --TLS1.2/1.3---> tlsterm(:18710) --plaintext--> upstream(:UPSTREAM)

No OpenSSL-SSLv3, no Docker/WSL/VM.
"""
import json
import os
import socket
import ssl
import threading
import time
import urllib.request

from tlslite import (
    HandshakeSettings,
    TLSConnection,
    X509,
    X509CertChain,
    parsePEMKey,
)

# --- config (env-overridable) --------------------------------------------
CERT      = os.environ.get("TLSTERM_CERT", "fesl.cer")           # EA cert (SSLv3 leg)
KEY       = os.environ.get("TLSTERM_KEY",  "fesl.key")
# Modern self-signed cert (modern-TLS leg). Auto-generated if absent.
MODERN_CERT = os.environ.get("TLSTERM_MODERN_CERT", "selfsigned.crt")
MODERN_KEY  = os.environ.get("TLSTERM_MODERN_KEY",  "selfsigned.key")
LISTEN    = os.environ.get("TLSTERM_LISTEN_HOST", "127.0.0.1")
LPORT     = int(os.environ.get("TLSTERM_LISTEN_PORT", "18710"))
UP_HOST   = os.environ.get("TLSTERM_UPSTREAM_HOST", "127.0.0.1")
UP_PORT   = int(os.environ.get("TLSTERM_UPSTREAM_PORT", "28710"))
# Where TLS-handshake captures are POSTed (the FastAPI webapp). Empty disables.
API_URL   = os.environ.get("MODKIT_API_URL", "http://127.0.0.1:8000").rstrip("/")

# SSLv3 leg is only wired up if the EA cert/key are present.
_ssl3_ready = os.path.exists(CERT) and os.path.exists(KEY)
if _ssl3_ready:
    _cert = X509(); _cert.parse(open(CERT).read())
    _chain = X509CertChain([_cert])
    _key = parsePEMKey(open(KEY).read(), private=True)


def log(msg):
    print(f"[tlsterm {time.strftime('%H:%M:%S')}] {msg}", flush=True)


# --- capture emit (best-effort, non-blocking) ----------------------------

def emit_capture(record):
    """POST one capture event to the webapp inspector. Fire-and-forget: a slow
    or absent webapp never blocks the game's handshake."""
    if not API_URL:
        return
    def _post():
        try:
            data = json.dumps(record).encode("utf-8")
            req = urllib.request.Request(
                API_URL + "/api/network-captures", data=data,
                headers={"Content-Type": "application/json"}, method="POST",
            )
            urllib.request.urlopen(req, timeout=3).read()
        except Exception:
            pass  # inspector is optional; the console log remains the record
    threading.Thread(target=_post, daemon=True).start()


# --- self-signed cert for the modern-TLS leg -----------------------------

def ensure_selfsigned(cert_path, key_path):
    """Guarantee a self-signed cert/key pair exists for the modern-TLS leg.
    Prefers the `cryptography` lib (no subprocess); falls back to the `openssl`
    CLI (the box ships OpenSSL 3.x). Returns True if a usable pair is present."""
    if os.path.exists(cert_path) and os.path.exists(key_path):
        return True
    # 1) cryptography (pure in-process, no CLI)
    try:
        import datetime as _dt
        from cryptography import x509
        from cryptography.hazmat.primitives import hashes, serialization
        from cryptography.hazmat.primitives.asymmetric import rsa
        from cryptography.x509.oid import NameOID

        key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
        name = x509.Name([
            x509.NameAttribute(NameOID.COMMON_NAME, "mercs2-pc.fesl.ea.com"),
            x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Modkit"),
        ])
        cert = (
            x509.CertificateBuilder()
            .subject_name(name).issuer_name(name)
            .public_key(key.public_key())
            .serial_number(x509.random_serial_number())
            .not_valid_before(_dt.datetime(2012, 1, 1))
            .not_valid_after(_dt.datetime(2042, 1, 1))
            .add_extension(x509.SubjectAlternativeName([
                x509.DNSName("mercs2-pc.fesl.ea.com"),
                x509.DNSName("fesl.ea.com"),
                x509.DNSName("localhost"),
            ]), critical=False)
            .sign(key, hashes.SHA256())
        )
        with open(key_path, "wb") as fh:
            fh.write(key.private_bytes(
                serialization.Encoding.PEM,
                serialization.PrivateFormat.TraditionalOpenSSL,
                serialization.NoEncryption(),
            ))
        with open(cert_path, "wb") as fh:
            fh.write(cert.public_bytes(serialization.Encoding.PEM))
        log(f"generated self-signed cert via cryptography -> {cert_path}")
        return True
    except Exception as exc:
        log(f"cryptography self-sign unavailable ({exc}); trying openssl CLI")
    # 2) openssl CLI fallback
    try:
        import subprocess
        subprocess.run(
            ["openssl", "req", "-x509", "-newkey", "rsa:2048", "-sha256",
             "-nodes", "-days", "3650", "-keyout", key_path, "-out", cert_path,
             "-subj", "/CN=mercs2-pc.fesl.ea.com/O=Modkit"],
            check=True, capture_output=True,
        )
        log(f"generated self-signed cert via openssl -> {cert_path}")
        return True
    except Exception as exc:
        log(f"WARN could not create self-signed cert ({exc}); modern-TLS leg disabled")
        return False


_modern_ready = ensure_selfsigned(MODERN_CERT, MODERN_KEY)
if _modern_ready:
    _modern_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    _modern_ctx.load_cert_chain(MODERN_CERT, MODERN_KEY)
    # Modern floor: TLS 1.2 minimum, 1.3 preferred. No client cert (TOFU host).
    try:
        _modern_ctx.minimum_version = ssl.TLSVersion.TLSv1_2
    except (ValueError, AttributeError):
        pass
    _modern_ctx.verify_mode = ssl.CERT_NONE


# --- SSLv3 handshake settings (the game's OpenSSL 0.9.8d offer) -----------

def _ssl3_settings():
    s = HandshakeSettings()
    s.minVersion = (3, 0)      # SSLv3
    s.maxVersion = (3, 0)
    s.cipherNames = ["rc4"]
    s.keyExchangeNames = ["rsa"]
    s.minKeySize = 512         # the game's EA cert is 512-bit (no modern floor)
    return s


# --- version peek (never consumes bytes) ---------------------------------

def peek_mode(sock):
    """Peek the TLS record header without consuming it. Returns "sslv3",
    "modern", or "unknown". The stock game's OpenSSL 0.9.8d sends record
    version 03 00 (SSLv3); the detour shim / any modern stack sends 03 01+."""
    deadline = time.time() + 5.0
    head = b""
    while len(head) < 3 and time.time() < deadline:
        try:
            head = sock.recv(6, socket.MSG_PEEK)
        except OSError:
            return "unknown"
        if len(head) < 3:
            time.sleep(0.02)
    if len(head) >= 3 and head[0] == 0x16 and head[1] == 0x03:
        return "sslv3" if head[2] == 0x00 else "modern"
    return "unknown"


# --- plaintext bridge shared by both legs --------------------------------

def _pump(src_read, dst_write, tag, stats):
    try:
        while True:
            data = src_read()
            if not data:
                log(f"  {tag}: clean EOF after {stats['n']}B")
                break
            stats["n"] += len(data)
            dst_write(data)
    except Exception as e:
        log(f"  {tag}: ENDED after {stats['n']}B with {type(e).__name__}: {e}")


def bridge(tls_read, tls_write, tls_close, peer, mode, cipher, ver):
    emit_capture({
        "protocol": "tls", "direction": "inbound", "peer_addr": peer,
        "server_port": LPORT, "host": "mercs2-pc.fesl.ea.com",
        "fesl_type": mode, "params": {"mode": mode, "version": ver, "cipher": cipher},
        "response_summary": f"handshake OK ({ver}, cipher={cipher}) -> {UP_HOST}:{UP_PORT}",
        "notes": f"tls-handshake:{mode}",
    })
    log(f"{peer} handshake OK ({mode}: {ver}, cipher={cipher}) -> bridging to {UP_HOST}:{UP_PORT}")
    try:
        up = socket.create_connection((UP_HOST, UP_PORT), timeout=5)
        # create_connection leaves the 5s timeout on the socket; clear it so
        # recv() blocks indefinitely while the FESL session idles between the
        # client's requests. (Otherwise the tunnel tears down after 5s of
        # server silence — before the game ever sends NuLogin.)
        up.settimeout(None)
    except Exception as e:
        log(f"{peer} upstream connect failed: {e!r}"); tls_close(); return

    s_up = {"n": 0}; s_dn = {"n": 0}

    def tls_to_up():
        _pump(tls_read, up.sendall, "tls->up(game-sent)", s_up)
        try: up.shutdown(socket.SHUT_WR)
        except Exception: pass

    def up_to_tls():
        _pump(lambda: up.recv(8192), tls_write, "up->tls(server-sent)", s_dn)
        try: tls_close()
        except Exception: pass

    a = threading.Thread(target=tls_to_up, daemon=True)
    b = threading.Thread(target=up_to_tls, daemon=True)
    a.start(); b.start(); a.join(); b.join()
    try: up.close()
    except Exception: pass
    log(f"{peer} closed (game-sent {s_up['n']}B, server-sent {s_dn['n']}B)")


# --- per-leg handlers -----------------------------------------------------

def handle_sslv3(conn, peer):
    if not _ssl3_ready:
        log(f"{peer} offered SSLv3 but no EA cert ({CERT}/{KEY}) loaded — dropping")
        conn.close(); return
    t = TLSConnection(conn)
    try:
        t.handshakeServer(certChain=_chain, privateKey=_key, settings=_ssl3_settings())
    except Exception as e:
        log(f"{peer} SSLv3 handshake FAILED: {e!r}")
        emit_capture({"protocol": "tls", "direction": "inbound", "peer_addr": peer,
                      "server_port": LPORT, "fesl_type": "sslv3",
                      "notes": f"tls-handshake-failed:sslv3:{type(e).__name__}"})
        try: conn.close()
        except Exception: pass
        return
    cs = t.session.cipherSuite if t.session else 0
    bridge(lambda: bytes(t.read(min=1, max=8192)), t.write, t.close,
           peer, "sslv3", f"0x{cs:04x}", "SSLv3")


def handle_modern(conn, peer):
    if not _modern_ready:
        log(f"{peer} offered modern TLS but no self-signed cert available — dropping")
        conn.close(); return
    try:
        tls = _modern_ctx.wrap_socket(conn, server_side=True)
    except Exception as e:
        log(f"{peer} modern-TLS handshake FAILED: {e!r}")
        emit_capture({"protocol": "tls", "direction": "inbound", "peer_addr": peer,
                      "server_port": LPORT, "fesl_type": "modern",
                      "notes": f"tls-handshake-failed:modern:{type(e).__name__}"})
        try: conn.close()
        except Exception: pass
        return
    ver = tls.version() or "TLS"
    cs = tls.cipher()
    cipher = cs[0] if cs else "?"
    bridge(lambda: tls.recv(8192), tls.sendall, tls.close,
           peer, "modern", cipher, ver)


def handle(conn, peer):
    try:
        mode = peek_mode(conn)
    except Exception as e:
        log(f"{peer} peek failed: {e!r}"); conn.close(); return
    if mode == "sslv3":
        handle_sslv3(conn, peer)
    elif mode == "modern":
        handle_modern(conn, peer)
    else:
        # Unknown first bytes: default to modern TLS (the forward-looking leg).
        log(f"{peer} unrecognized ClientHello — defaulting to modern TLS")
        handle_modern(conn, peer)


def main():
    legs = []
    if _ssl3_ready: legs.append(f"SSLv3/RC4({CERT})")
    if _modern_ready: legs.append(f"modern-TLS({MODERN_CERT})")
    ls = socket.socket(); ls.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    ls.bind((LISTEN, LPORT)); ls.listen(8)
    log(f"listening (dual-mode: {', '.join(legs) or 'NONE'}) on {LISTEN}:{LPORT} "
        f"-> upstream {UP_HOST}:{UP_PORT}  inspector={API_URL or '(disabled)'}")
    while True:
        conn, addr = ls.accept()
        peer = f"{addr[0]}:{addr[1]}"
        log(f"{peer} connected")
        threading.Thread(target=handle, args=(conn, peer), daemon=True).start()


if __name__ == "__main__":
    main()
