#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/OnyxJeff/aesir/main/misc/build.func)

# App Metadata
APP="Sindri"
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
build_container
description

pct exec "$CTID" -- bash -c "cd /opt/woodpecker && docker-compose up -d"

# Done
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} is now forging pipelines!${CL}"
echo -e "${INFO}${YW} Access the Woodpecker CI web UI at:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
echo -e "${INFO} To register Brokkr later, use this Agent Secret:"
echo -e "${TAB}${WOODPECKER_AGENT_SECRET}"