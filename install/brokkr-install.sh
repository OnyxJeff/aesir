#!/usr/bin/env bash
set -euo pipefail

APP="woodpecker-agent"
INSTALL_DIR="/opt/$APP"
ENV_FILE="$INSTALL_DIR/.env"
COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"

msg() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

echo ""
msg "Installing Docker & Docker Compose..."
apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release unzip jq docker.io docker-compose

echo ""
msg "Creating user and directory..."
useradd -r -m -d "$INSTALL_DIR" -s /usr/sbin/nologin "$APP" || true
mkdir -p "$INSTALL_DIR/data"
chmod 777 "$INSTALL_DIR/data"
chown -R "$APP:$APP" "$INSTALL_DIR"

# Prompt for Sindri URL and Agent Secret
echo ""
msg "Prompting for Sindri server url & Agent Secret..."
read -p "Enter Sindri (Woodpecker Server) URL (e.g. sindri.local [Do NOT include http://]): " WOODPECKER_SERVER
read -p "Enter Woodpecker Agent Secret: " WOODPECKER_AGENT_SECRET

echo ""
msg "Writing .env file..."
cat > "$ENV_FILE" <<EOF
WOODPECKER_SERVER=${WOODPECKER_SERVER}:9000
WOODPECKER_AGENT_SECRET=${WOODPECKER_AGENT_SECRET}
WOODPECKER_MAX_WORKFLOWS=2
WOODPECKER_AGENT_LABELS=linux,amd64,proxmox
EOF

echo ""
msg "Writing docker-compose.yml..."
cat > "$COMPOSE_FILE" <<EOF
services:
  brokkr:
    image: woodpeckerci/woodpecker-agent:v3
    restart: unless-stopped
    env_file: .env
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    labels:
      - "woodpecker.platform=linux/amd64"
      - "woodpecker.platform=linux/arm64"
EOF

cd "$INSTALL_DIR"

echo ""
msg "Starting Woodpecker-agent CD using Docker Compose..."
docker-compose up -d

echo ""
msg "✅ Woodpecker-Agent CD is now running!"