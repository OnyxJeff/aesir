#!/usr/bin/env bash
set -euo pipefail

APP="woodpecker"
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

msg "Prompting for Gitea URL..."
read -p "Enter your Gitea URL [default: http://gitea.local]: " GITEA_URL
GITEA_URL=${GITEA_URL:-http://gitea.local}

WOODPECKER_AGENT_SECRET=$(openssl rand -hex 16)

msg "Writing .env file..."
cat > "$ENV_FILE" <<EOF
WOODPECKER_OPEN=true
WOODPECKER_HOST=http://localhost:8000
WOODPECKER_GITEA=true
WOODPECKER_GITEA_URL=$GITEA_URL
WOODPECKER_GITEA_CLIENT=replace-me
WOODPECKER_GITEA_SECRET=replace-me
WOODPECKER_AGENT_SECRET=$WOODPECKER_AGENT_SECRET
EOF

msg "Writing docker-compose.yml..."
cat > "$COMPOSE_FILE" <<EOF
services:
  server:
    image: woodpeckerci/woodpecker-server:latest
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./data:/var/lib/woodpecker
    ports:
      - 8000:8000
      - 9000:9000
EOF

cd "$INSTALL_DIR"

msg "Starting Woodpecker CI using Docker Compose..."
docker-compose up -d

msg "✅ Woodpecker CI is now running!"
echo "🛠️ To register Brokkr agent, use this secret:"
echo "🔑 $WOODPECKER_AGENT_SECRET"
