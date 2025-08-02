#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/OnyxJeff/aesir/main/misc/build.func)

# App Metadata
APP="Sindri"
var_install="${var_install:-woodpecker}"
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

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  get_latest_release() {
    curl -fsSL https://api.github.com/repos/"$1"/releases/latest | grep '"tag_name":' | cut -d'"' -f4
  }

  msg_info "Updating base system"
  $STD apt-get update
  $STD apt-get -y upgrade
  msg_ok "Base system updated"

  msg_info "Updating Docker Engine"
  $STD apt-get install --only-upgrade -y docker-ce docker-ce-cli containerd.io
  msg_ok "Docker Engine updated"

  if [[ -f /usr/local/lib/docker/cli-plugins/docker-compose ]]; then
    COMPOSE_BIN="/usr/local/lib/docker/cli-plugins/docker-compose"
    COMPOSE_NEW_VERSION=$(get_latest_release "docker/compose")
    msg_info "Updating Docker Compose to $COMPOSE_NEW_VERSION"
    curl -fsSL "https://github.com/docker/compose/releases/download/${COMPOSE_NEW_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
      -o "$COMPOSE_BIN"
    chmod +x "$COMPOSE_BIN"
    msg_ok "Docker Compose updated"
  fi

    msg_info "Cleaning up"
  $STD apt-get -y autoremove
  $STD apt-get -y autoclean
  msg_ok "Cleanup complete"
  exit
}

start
build_container
description

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