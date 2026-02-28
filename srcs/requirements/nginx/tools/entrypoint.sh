#!/usr/bin/env bash
set -euo pipefail

: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"

SSL_DIR="/etc/nginx/ssl"
CRT="${SSL_DIR}/inception.crt"
KEY="${SSL_DIR}/inception.key"

mkdir -p "${SSL_DIR}"

sed -i "s/DOMAIN_PLACEHOLDER/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

# Generate self-signed cert only if not present (idempotent)
if [ ! -f "${CRT}" ] || [ ! -f "${KEY}" ]; then
  openssl req -x509 -nodes \
    -newkey rsa:2048 \
    -days 365 \
    -keyout "${KEY}" \
    -out "${CRT}" \
    -subj "/C=JP/ST=Tokyo/L=Tokyo/O=42/OU=Inception/CN=${DOMAIN_NAME}"
fi

exec "$@"
