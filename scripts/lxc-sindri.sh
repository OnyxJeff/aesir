#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# App Metadata
APP="Sindri (Woodpecker CI)"
var_tags="${var_tags:-ci;woodpecker;pipeline}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

# Header and Setup
header_info "$APP"
variables
color
catch_errors
start

# Validate storage supports rootdir
if ! pvesm status --verbose | grep -A3 "$var_storage" | grep -q rootdir; then
  msg_error "Storage '$var_storage' does not support LXC containers (missing 'rootdir')"
  echo -e "${INFO} Tip: Use 'local' or a ZFS/dir storage that supports containers."
  exit 1
fi

build_container
description

# Optional: Docker and Tools
msg_info "Installing Docker and dependencies"
pct exec "$CTID" -- bash -c "apt-get update && apt-get install -y docker.io curl git"
msg_ok "Installed Docker"

# Prompt for Gitea URL
read -p "Enter the URL of your Gitea instance (default: http://gitea.local): " GITEA_URL
GITEA_URL=${GITEA_URL:-http://gitea.local}

# Create Woodpecker directories
msg_info "Creating Woodpecker CI config and data directories"
pct exec "$CTID" -- mkdir -p /opt/woodpecker/data
msg_ok "Directories ready"

# Generate Woodpecker secret
WOODPECKER_AGENT_SECRET=$(openssl rand -hex 16)
msg_info "Generated Agent Secret for Brokkr: $WOODPECKER_AGENT_SECRET"

# Create .env file inside container
pct exec "$CTID" -- bash -c "cat > /opt/woodpecker/.env" <<EOF
WOODPECKER_OPEN=true
WOODPECKER_HOST=http://localhost:8000
WOODPECKER_GITEA=true
WOODPECKER_GITEA_URL=$GITEA_URL
WOODPECKER_GITEA_CLIENT=replace-me
WOODPECKER_GITEA_SECRET=replace-me
WOODPECKER_AGENT_SECRET=$WOODPECKER_AGENT_SECRET
EOF

msg_ok ".env file written inside container"

# Launch Woodpecker server container
msg_info "Launching Woodpecker CI server (Docker)"
pct exec "$CTID" -- docker run -d \
  --name woodpecker-server \
  --restart unless-stopped \
  -v /opt/woodpecker/data:/var/lib/woodpecker \
  -v /opt/woodpecker/.env:/etc/woodpecker.env \
  -p 8000:8000 \
  -p 9000:9000 \
  --env-file /etc/woodpecker.env \
  woodpeckerci/woodpecker-server:latest
msg_ok "Woodpecker server is running"

# Done
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} is now forging pipelines!${CL}"
echo -e "${INFO}${YW} Access the Woodpecker CI web UI at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO} To register Brokkr later, use this Agent Secret:"
echo -e "${TAB}${WOODPECKER_AGENT_SECRET}"
