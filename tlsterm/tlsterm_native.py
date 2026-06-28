"""Native-Windows tlsterm: SSLv3+RC4 terminator for Mercenaries 2's FESL client.

Pure-Python (tlslite-ng) replacement for the Docker stunnel+OpenSSL-1.0.2 sidecar.
Accepts the game's SSLv3/RC4 handshake with the genuine EA fesl.cer, decrypts,
and bridges plaintext FESL to coopserver. No OpenSSL-SSLv3, no Docker/WSL/VM.

  game --SSLv3/RC4--> tlsterm(:18710) --plaintext--> coopserver(:UPSTREAM)
"""
import os, socket, threading, sys, time
from tlslite import TLSConnection, X509, X509CertChain, parsePEMKey, HandshakeSettings

CERT      = os.environ.get("TLSTERM_CERT", "fesl.cer")
KEY       = os.environ.get("TLSTERM_KEY",  "fesl.key")
LISTEN    = os.environ.get("TLSTERM_LISTEN_HOST", "127.0.0.1")
LPORT     = int(os.environ.get("TLSTERM_LISTEN_PORT", "18710"))
UP_HOST   = os.environ.get("TLSTERM_UPSTREAM_HOST", "127.0.0.1")
UP_PORT   = int(os.environ.get("TLSTERM_UPSTREAM_PORT", "28710"))

_cert = X509(); _cert.parse(open(CERT).read())
_chain = X509CertChain([_cert])
_key = parsePEMKey(open(KEY).read(), private=True)

def _settings():
    s = HandshakeSettings()
    s.minVersion = (3, 0)      # SSLv3
    s.maxVersion = (3, 0)
    s.cipherNames = ["rc4"]
    s.keyExchangeNames = ["rsa"]
    s.minKeySize = 512         # the game's cert is 512-bit (no modern floor)
    return s

def log(msg):
    print(f"[tlsterm {time.strftime('%H:%M:%S')}] {msg}", flush=True)

def _pump(src_read, dst_write, tag, stats):
    try:
        while True:
            data = src_read()
            if not data:
                log(f"  {tag}: clean EOF after {stats['n']}B")
                break
            stats['n'] += len(data)
            dst_write(data)
    except Exception as e:
        log(f"  {tag}: ENDED after {stats['n']}B with {type(e).__name__}: {e}")

def handle(conn, peer):
    t = TLSConnection(conn)
    try:
        t.handshakeServer(certChain=_chain, privateKey=_key, settings=_settings())
    except Exception as e:
        log(f"{peer} handshake FAILED: {e!r}")
        try: conn.close()
        except Exception: pass
        return
    cs = t.session.cipherSuite if t.session else "?"
    log(f"{peer} handshake OK (SSLv3, cipher=0x{cs:04x}) -> bridging to {UP_HOST}:{UP_PORT}")
    try:
        up = socket.create_connection((UP_HOST, UP_PORT), timeout=5)
        # create_connection leaves the 5s timeout on the socket; clear it so
        # recv() blocks indefinitely while the FESL session idles between the
        # client's requests. (Otherwise the tunnel tears down after 5s of
        # server silence — before the game ever sends NuLogin.)
        up.settimeout(None)
    except Exception as e:
        log(f"{peer} upstream connect failed: {e!r}"); t.close(); return

    s_up = {'n': 0}; s_dn = {'n': 0}
    def tls_to_up():
        _pump(lambda: bytes(t.read(min=1, max=8192)), up.sendall, "tls->up(game-sent)", s_up)
        try: up.shutdown(socket.SHUT_WR)
        except Exception: pass
    def up_to_tls():
        _pump(lambda: up.recv(8192), t.write, "up->tls(server-sent)", s_dn)
        try: t.close()
        except Exception: pass

    a = threading.Thread(target=tls_to_up, daemon=True)
    b = threading.Thread(target=up_to_tls, daemon=True)
    a.start(); b.start(); a.join(); b.join()
    try: up.close()
    except Exception: pass
    log(f"{peer} closed")

def main():
    ls = socket.socket(); ls.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    ls.bind((LISTEN, LPORT)); ls.listen(8)
    log(f"listening (SSLv3/RC4) on {LISTEN}:{LPORT}  cert={CERT}  -> upstream {UP_HOST}:{UP_PORT}")
    while True:
        conn, addr = ls.accept()
        peer = f"{addr[0]}:{addr[1]}"
        log(f"{peer} connected")
        threading.Thread(target=handle, args=(conn, peer), daemon=True).start()

if __name__ == "__main__":
    main()
