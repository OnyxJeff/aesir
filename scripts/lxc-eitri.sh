#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/OnyxJeff/aesir/main/misc/build.func)

# App Metadata
APP="Eitri"
var_tags="${var_tags:-cd;eitri;woodpecker;pipeline;agent}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

# Done
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} is now forging pipelines!${CL}"
echo -e "${INFO}${YW} Agent will communicate with Woodpecker Server ${CL}"