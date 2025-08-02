#!/usr/bin/env bash

set -e

# COLORS
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Finding next available CTID...${NC}"
CTID=$(for i in $(seq 100 999); do if ! qm status "$i" &>/dev/null && ! pct status "$i" &>/dev/null; then echo "$i"; break; fi; done)

# DEFAULTS
TEMPLATE="debian-12-standard_12.2-1_amd64.tar.zst"
STORAGE="local-lvm"
HOSTNAME="brokkr"
DISK=8
RAM=2048
CORES=2
BRIDGE="vmbr0"
IP="dhcp"

# USER INPUT WITH DEFAULTS
read -p "Use CTID (default: $CTID): " input
CTID=${input:-$CTID}

read -p "Hostname (default: $HOSTNAME): " input
HOSTNAME=${input:-$HOSTNAME}

read -p "Storage (default: $STORAGE): " input
STORAGE=${input:-$STORAGE}

read -p "Disk size in GB (default: $DISK): " input
DISK=${input:-$DISK}

read -p "RAM in MB (default: $RAM): " input
RAM=${input:-$RAM}

read -p "Cores (default: $CORES): " input
CORES=${input:-$CORES}

read -p "Bridge (default: $BRIDGE): " input
BRIDGE=${input:-$BRIDGE}

read -p "IP Address [e.g., dhcp or 192.168.1.100/24,gw=192.168.1.1] (default: $IP): " input
IP=${input:-$IP}

echo -e "${YELLOW}📦 Preparing container '$HOSTNAME' ($CTID)...${NC}"

# Download LXC template if missing
if ! ls /var/lib/vz/template/cache/$TEMPLATE &>/dev/null; then
    echo -e "${YELLOW}Downloading LXC template: $TEMPLATE...${NC}"
    pveam update
    pveam download local "$TEMPLATE"
fi

# Create container
pct create "$CTID" "local:vztmpl/$TEMPLATE" \
  -hostname "$HOSTNAME" \
  -memory "$RAM" \
  -cores "$CORES" \
  -net0 name=eth0,bridge=$BRIDGE,ip=$IP \
  -rootfs "$STORAGE:$DISK" \
  -features nesting=1 \
  -unprivileged 1 \
  -onboot 1

# Start container
echo -e "${YELLOW}🚀 Starting container...${NC}"
pct start "$CTID"

sleep 5

# Install Docker + tools inside container
echo -e "${YELLOW}🐳 Installing Docker and basic tools inside container...${NC}"
pct exec "$CTID" -- bash -c "apt-get update && apt-get install -y docker.io curl git"

# TODO: Add runner agent setup here (example below)
# echo -e "${YELLOW}⚙️ Setting up CI/CD runner agent...${NC}"
# pct exec "$CTID" -- bash -c "docker run -d --restart unless-stopped --name woodpecker-agent woodpeckerci/woodpecker-agent:latest"

echo -e "${GREEN}✅ Container '$HOSTNAME' ($CTID) created, started, Docker installed, and ready for runner setup!${NC}"
