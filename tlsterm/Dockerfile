# Legacy-TLS terminator for Mercenaries 2's FESL client.
#
# The game speaks SSLv3 with RC4-SHA/RC4-MD5 (EA's OpenSSL 0.9.8d era). Modern
# OpenSSL has all three removed, so we compile OpenSSL 1.0.2 with SSLv3 + weak
# ciphers enabled and build stunnel against it. stunnel terminates the SSLv3
# handshake on :18710 and forwards the decrypted plaintext FESL to coopserver,
# whose FESL handler + capture already work on plaintext.

FROM debian:bullseye AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential wget ca-certificates perl zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src

# --- OpenSSL 1.0.2u with SSLv3 + weak ciphers ---
RUN wget -q -O openssl.tgz "https://www.openssl.org/source/old/1.0.2/openssl-1.0.2u.tar.gz" \
     || wget -q -O openssl.tgz "https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_0_2u.tar.gz" \
 && tar xf openssl.tgz && mv openssl-* openssl-src
RUN cd openssl-src \
 && ./config --prefix=/opt/ssl102 shared enable-ssl3 enable-ssl3-method enable-weak-ssl-ciphers \
 && make -j"$(nproc)" && make install_sw

# --- stunnel linked against the legacy OpenSSL ---
# /downloads/ only keeps the latest; pinned versions live under /archive/5.x/.
RUN wget -q -O stunnel.tgz "https://www.stunnel.org/archive/5.x/stunnel-5.74.tar.gz" \
     || wget -q -O stunnel.tgz "https://www.stunnel.org/archive/5.x/stunnel-5.72.tar.gz" \
     || wget -q -O stunnel.tgz "https://www.stunnel.org/downloads/stunnel-5.78.tar.gz" \
 && tar xf stunnel.tgz && mv stunnel-* stunnel-src
RUN cd stunnel-src \
 && ./configure --with-ssl=/opt/ssl102 --disable-systemd --prefix=/opt/stunnel \
 && make -j"$(nproc)" && make install

FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y --no-install-recommends zlib1g \
    && rm -rf /var/lib/apt/lists/*
COPY --from=build /opt/ssl102 /opt/ssl102
COPY --from=build /opt/stunnel /opt/stunnel
ENV LD_LIBRARY_PATH=/opt/ssl102/lib
# EA's genuine FESL server cert + private key (the "dirtysock" cert the game pins
# against). 512-bit RSA / MD5 — only our OpenSSL 1.0.2 build will load it.
COPY fesl.cer fesl.key /opt/fesl/
COPY stunnel.conf /opt/stunnel/etc/stunnel.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
