#!/usr/bin/env bash
set -euo pipefail

APP="Woodpecker"
REPO="woodpecker-ci/woodpecker"
INSTALL_DIR="/opt/woodpecker"

msg() { echo -e "\033[1;32m[INFO]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

msg "Updating system and installing dependencies..."
apt-get update -y
apt-get install -y curl unzip ca-certificates jq

msg "Creating woodpecker user and directories..."
useradd -r -m -d "$INSTALL_DIR" -s /usr/sbin/nologin woodpecker || true
mkdir -p "$INSTALL_DIR"
chown woodpecker:woodpecker "$INSTALL_DIR"

msg "Downloading latest Woodpecker binary..."
LATEST=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | jq -r '.tag_name')
ARCH=$(dpkg --print-architecture)

if [[ "$ARCH" != "amd64" ]]; then
  err "Unsupported architecture: $ARCH. Only amd64 is supported."
  exit 1
fi

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST}/woodpecker_${LATEST}_linux_amd64.tar.gz"

curl -L "$DOWNLOAD_URL" -o /tmp/woodpecker.tar.gz
tar -xzvf /tmp/woodpecker.tar.gz -C /tmp
install -m 755 /tmp/woodpecker "$INSTALL_DIR/woodpecker"

msg "Creating systemd service..."
cat >/etc/systemd/system/woodpecker.service <<EOF
[Unit]
Description=Woodpecker CI Server
After=network.target

[Service]
User=woodpecker
Group=woodpecker
ExecStart=${INSTALL_DIR}/woodpecker server
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

msg "Enabling and starting woodpecker.service..."
systemctl daemon-reload
systemctl enable woodpecker.service
systemctl start woodpecker.service

msg "Woodpecker CI installation completed successfully!"
msg "You can check status with: systemctl status woodpecker"
