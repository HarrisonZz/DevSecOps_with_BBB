#!/bin/bash

set -euo pipefail

readonly NODE_IP="192.168.20.11"
readonly TLS_SAN_1="192.168.20.11"
readonly TLS_SAN_2="192.168.6.1"
readonly TIMEZONE="Asia/Taipei"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

log "Updating Debian packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq || error_exit "Failed to update package list"

log "Installing required packages..."
apt-get install -y \
    curl \
    ca-certificates \
    chrony \
    || error_exit "Failed to install packages"

log "Configuring timezone and time synchronization..."
timedatectl set-timezone "$TIMEZONE"
timedatectl set-ntp true

log "Configuring chrony NTP service..."
cat > /etc/chrony/chrony.conf << 'EOF'
server time.google.com iburst

allow 192.168.6.0/24
allow 192.168.20.0/24

driftfile /var/lib/chrony/chrony.drift
makestep 1.0 3
rtcsync

logdir /var/log/chrony
log measurements statistics tracking
EOF

systemctl restart chrony
systemctl enable chrony

if systemctl is-active --quiet k3s 2>/dev/null; then
    log "K3S is already running, skipping installation"
else
    log "Installing K3S Server..."

    export INSTALL_K3S_EXEC="server \
        --node-ip $NODE_IP \
        --tls-san $TLS_SAN_1 \
        --tls-san $TLS_SAN_2"
    curl -sfL https://get.k3s.io | sh - || error_exit "K3S installation failed"
fi