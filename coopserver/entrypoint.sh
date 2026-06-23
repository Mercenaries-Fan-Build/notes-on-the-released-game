#!/usr/bin/env sh
# Generate a self-signed cert on first run (the game's ancient OpenSSL client is
# expected to accept it), then launch the capture server.
set -e

CERT_FILE="${COOP_CERT_FILE:-/app/certs/server.crt}"
KEY_FILE="${COOP_KEY_FILE:-/app/certs/server.key}"
CERT_DIR="$(dirname "$CERT_FILE")"

mkdir -p "$CERT_DIR"
if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "[entrypoint] generating self-signed cert for fesl.ea.com ..."
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "$KEY_FILE" -out "$CERT_FILE" -days 3650 \
        -subj "/CN=fesl.ea.com/O=Modkit" \
        -addext "subjectAltName=DNS:fesl.ea.com,DNS:mercs2-pc.fesl.ea.com,DNS:*.fesl.ea.com,DNS:messaging.ea.com,DNS:*.ea.com,DNS:locate.madserver.net,DNS:*.madserver.net" \
        2>/dev/null || \
    openssl req -x509 -newkey rsa:2048 -nodes \
        -keyout "$KEY_FILE" -out "$CERT_FILE" -days 3650 \
        -subj "/CN=fesl.ea.com/O=Modkit"
fi

exec python -u main.py
