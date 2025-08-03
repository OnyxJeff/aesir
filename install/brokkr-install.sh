#!/usr/bin/env bash
set -euo pipefail

APP="woodpecker-agent"
INSTALL_DIR="/opt/$APP"
ENV_FILE="$INSTALL_DIR/.env"
COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"

msg() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

msg "Installing Docker & Docker Compose..."
apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release unzip jq docker.io docker-compose

msg "Creating user and directory..."
useradd -r -m -d "$INSTALL_DIR" -s /usr/sbin/nologin "$APP" || true
mkdir -p "$INSTALL_DIR/data"
chown -R "$APP:$APP" "$INSTALL_DIR"

msg "Prompting for Sindri server url & Agent Secret..."
read -p "Enter Sindri (Woodpecker server) URL/IP address [without a port number]: " SINDRI_URL
read -p "Enter Agent Secret (from Sindri install): " AGENT_SECRET

msg "Writing .env file..."
cat > "$ENV_FILE" <<EOF
WOODPECKER_SERVER=$SINDRI_URL
WOODPECKER_AGENT_SECRET=$AGENT_SECRET
EOF

msg "Writing docker-compose.yml..."
cat > "$COMPOSE_FILE" <<EOF
# Prompt for Sindri URL and Agent Secret
read -p "Enter Sindri (Woodpecker Server) URL (e.g. http://sindri.local:8000): " WOODPECKER_SERVER
read -p "Enter Woodpecker Agent Secret: " WOODPECKER_AGENT_SECRET

mkdir -p /opt/brokkr
cat > /opt/brokkr/.env <<EOF
WOODPECKER_AGENT_SECRET=${WOODPECKER_AGENT_SECRET}
WOODPECKER_SERVER=${WOODPECKER_SERVER}
WOODPECKER_HOST=http://localhost:9000
EOF

cat > /opt/brokkr/docker-compose.yml <<EOF
services:
  brokkr:
    image: woodpeckerci/woodpecker-agent:latest
    restart: unless-stopped
    environment:
      - WOODPECKER_AGENT_SECRET=\${WOODPECKER_AGENT_SECRET}
      - WOODPECKER_SERVER=\${WOODPECKER_SERVER}
      - WOODPECKER_HOST=http://localhost:9000
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
EOF

cd "$INSTALL_DIR"

msg "Starting Woodpecker CI using Docker Compose..."
docker-compose up -d

echo ""
msg "✅ Woodpecker CI is now running!"
echo "🛠️ To register Brokkr agent, use this secret:"
echo "🔑 $WOODPECKER_AGENT_SECRET"
