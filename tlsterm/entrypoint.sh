#!/bin/sh
# Build the stunnel cert. Preferred: EA's genuine FESL cert+key (fesl.cer/fesl.key
# from the TeknoGods server) — the game pins against this, so it completes the
# handshake. Fallback: a self-signed cert (the game will reject it, capture only).
set -e
CERT=/certs/server.pem
mkdir -p /certs

if [ -f /opt/fesl/fesl.cer ] && [ -f /opt/fesl/fesl.key ]; then
    echo "[tlsterm] using EA FESL cert (fesl.cer + fesl.key) — pins to OTG3 CA"
    cat /opt/fesl/fesl.key /opt/fesl/fesl.cer > "$CERT"
elif [ ! -f "$CERT" ]; then
    echo "[tlsterm] WARNING: no EA cert found — generating self-signed (game will reject)"
    /opt/ssl102/bin/openssl req -x509 -newkey rsa:1024 -sha1 -nodes \
        -keyout /tmp/key.pem -out /tmp/cert.pem -days 3650 \
        -subj "/CN=mercs2-pc.fesl.ea.com/O=Modkit"
    cat /tmp/key.pem /tmp/cert.pem > "$CERT"
fi
chmod 600 "$CERT" 2>/dev/null || true

echo "[tlsterm] starting stunnel (SSLv3 + RC4 -> coopserver:18710)"
exec /opt/stunnel/bin/stunnel /opt/stunnel/etc/stunnel.conf
