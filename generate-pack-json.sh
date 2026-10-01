#!/usr/bin/env bash
set -euo pipefail

DOMAIN="${DOMAIN:-iphonmods.online}"
OUT="${OUT:-.}"

mkdir -p "$OUT"

CA_KEY="$OUT/ca.key"
CA_CRT="$OUT/ca.crt"
SERVER_KEY="$OUT/server.key"
SERVER_CSR="$OUT/server.csr"
SERVER_CRT="$OUT/server.crt"
SAN_CFG="$OUT/san.cnf"
PACK_JSON="$OUT/pack.json"

if [ ! -f "$CA_KEY" ] || [ ! -f "$CA_CRT" ]; then
  openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
    -nodes \
    -keyout "$CA_KEY" \
    -out "$CA_CRT" \
    -subj "/CN=Feather Local CA/O=Feather"
fi

if [ ! -f "$SERVER_KEY" ] || [ ! -f "$SERVER_CSR" ]; then
  openssl req -new -newkey rsa:2048 -nodes \
    -keyout "$SERVER_KEY" \
    -out "$SERVER_CSR" \
    -subj "/CN=*.$DOMAIN/O=Feather"
fi

cat > "$SAN_CFG" <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
CN = *.$DOMAIN

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.$DOMAIN
DNS.2 = $DOMAIN
EOF

if [ ! -f "$SERVER_CRT" ]; then
  openssl x509 -req -in "$SERVER_CSR" \
    -CA "$CA_CRT" -CAkey "$CA_KEY" -CAcreateserial \
    -out "$SERVER_CRT" -days 365 -sha256 \
    -extfile "$SAN_CFG" -extensions v3_req
fi

CERT_B64="$(base64 "$SERVER_CRT" | tr -d '\n')"
CA_B64="$(base64 "$CA_CRT" | tr -d '\n')"
KEY_FULL="$(cat "$SERVER_KEY")"
KEY_LEN=${#KEY_FULL}
KEY_HALF=$((KEY_LEN / 2))
KEY1="${KEY_FULL:0:$KEY_HALF}"
KEY2="${KEY_FULL:$KEY_HALF}"

# We split the key into two strings because the project expects key1 + key2 in JSON.
cat > "$PACK_JSON" <<EOF
{
  "cert": "-----BEGIN CERTIFICATE-----\n$(printf '%s' "$CERT_B64" | fold -w 64 | paste -sd '\\n' - | sed 's/^/ /' | tr -d '\n')\n-----END CERTIFICATE-----",
  "ca": "-----BEGIN CERTIFICATE-----\n$(printf '%s' "$CA_B64" | fold -w 64 | paste -sd '\\n' - | sed 's/^/ /' | tr -d '\n')\n-----END CERTIFICATE-----",
  "key1": "$(printf '%s' "$KEY1" | sed ':a;N;$!ba;s/\n/\\n/g')",
  "key2": "$(printf '%s' "$KEY2" | sed ':a;N;$!ba;s/\n/\\n/g')",
  "info": {
    "issuer": {
      "commonName": "Feather Local CA"
    },
    "domains": {
      "commonName": "*.$DOMAIN"
    }
  }
}
EOF

echo "Generated: $PACK_JSON"
echo "Now upload the file to GitHub Pages and point DNS for pack.$DOMAIN to GitHub Pages."
