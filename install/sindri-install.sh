#!/usr/bin/env bash
set -euo pipefail

APP="Woodpecker CI"
INSTALL_DIR="/opt/woodpecker"
REPO="woodpeckerci/woodpecker-server"
DEFAULT_GITEA_URL="http://gitea.local"
ENV_FILE="$INSTALL_DIR/.env"

msg() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

# Ask for Gitea URL or use default
read -rp "Enter your Gitea URL [default: $DEFAULT_GITEA_URL]: " GITEA_URL
GITEA_URL="${GITEA_URL:-$DEFAULT_GITEA_URL}"

msg "Installing Docker & Docker Compose..."
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
    jq

# Add Docker's official GPG key and repo
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor \
    -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

msg "Docker installed successfully"

# Set up Woodpecker directories
msg "Creating Woodpecker directories..."
mkdir -p "$INSTALL_DIR"/{data,logs}
chown -R root:root "$INSTALL_DIR"

# Generate Woodpecker agent secret
WOODPECKER_AGENT_SECRET=$(openssl rand -hex 16)
msg "Generated Woodpecker Agent Secret: $WOODPECKER_AGENT_SECRET"

# Create environment file
cat > "$ENV_FILE" <<EOF
WOODPECKER_OPEN=true
WOODPECKER_HOST=http://localhost:8000
WOODPECKER_GITEA=true
WOODPECKER_GITEA_URL=${GITEA_URL}
WOODPECKER_GITEA_CLIENT=replace-me
WOODPECKER_GITEA_SECRET=replace-me
WOODPECKER_AGENT_SECRET=${WOODPECKER_AGENT_SECRET}
EOF

msg "Woodpecker environment file created at $ENV_FILE"

# Deploy container
msg "Launching Woodpecker CI server container..."
docker run -d \
  --name woodpecker-server \
  --restart unless-stopped \
  -v "$INSTALL_DIR/data:/var/lib/woodpecker" \
  -v "$ENV_FILE:/etc/woodpecker.env" \
  -p 8000:8000 \
  -p 9000:9000 \
  --env-file /etc/woodpecker.env \
  "$REPO:latest"

msg "Woodpecker CI server is up and running!"
echo ""
echo -e "➡️  Access Woodpecker UI at: \033[1;34mhttp://<your-container-ip>:8000\033[0m"
echo -e "🔑 Use the following Agent Secret for Brokkr: \033[1;33m${WOODPECKER_AGENT_SECRET}\033[0m"
