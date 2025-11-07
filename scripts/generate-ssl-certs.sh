#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

HOSTNAME=${1:-wooco.localhost}
SSL_DIR="$(dirname "$0")/../ssl"

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

echo -e "${GREEN}Generating SSL certificates for: ${HOSTNAME}${NC}"

# Check if mkcert is available
if command -v mkcert >/dev/null 2>&1; then
    echo -e "${GREEN}Using mkcert to generate locally-trusted certificates...${NC}"

    cd "$SSL_DIR"
    mkcert -install
    mkcert "$HOSTNAME" "*.${HOSTNAME}" localhost 127.0.0.1 ::1

    # Rename files to standard names
    mv "${HOSTNAME}+4.pem" cert.pem 2>/dev/null || true
    mv "${HOSTNAME}+4-key.pem" key.pem 2>/dev/null || true

    echo -e "${GREEN}✓ Locally-trusted SSL certificates generated!${NC}"
    echo -e "${GREEN}✓ No browser warnings will appear${NC}"
else
    echo -e "${YELLOW}mkcert not found. Generating self-signed certificates...${NC}"
    echo -e "${YELLOW}Note: Browser will show security warnings (this is normal for self-signed certs)${NC}"
    echo -e "${YELLOW}Install mkcert for trusted certificates: https://github.com/FiloSottile/mkcert${NC}"

    # Generate self-signed certificate with openssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$SSL_DIR/key.pem" \
        -out "$SSL_DIR/cert.pem" \
        -subj "/C=US/ST=State/L=City/O=Development/CN=${HOSTNAME}" \
        -addext "subjectAltName=DNS:${HOSTNAME},DNS:*.${HOSTNAME},DNS:localhost,IP:127.0.0.1"

    echo -e "${GREEN}✓ Self-signed SSL certificates generated${NC}"
    echo -e "${YELLOW}⚠ Browser will show security warnings (click 'Advanced' and 'Proceed')${NC}"
fi

echo ""
echo -e "${GREEN}SSL certificates created at:${NC}"
echo "  Certificate: $SSL_DIR/cert.pem"
echo "  Private Key: $SSL_DIR/key.pem"
echo ""
