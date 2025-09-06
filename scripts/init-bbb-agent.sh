#!/bin/bash

readonly BBB_HOST="${1:-192.168.6.2}"  # BBB IP 位址
readonly BBB_USER="${2:-debian}"          # BBB 使用者
readonly K3S_SERVER_IP="192.168.20.11"   # K3S Server IP
readonly K3S_API_PORT="400"


log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf
echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf

log "Configuring network interfaces..."

sudo dhclient usb0 || true
sudo ip route add 192.168.20.0/24 via 192.168.6.1 dev usb1 || true

log "Configuring time synchronization..."

cat <<EOF | sudo tee /etc/chrony/chrony.conf > /dev/null
server $K3S_SERVER_IP iburst
makestep 1.0 3
rtcsync
EOF

sudo systemctl restart chrony
sudo systemctl enable chrony
sudo systemctl disable --now systemd-timesyncd || true

# 強制時間同步
sudo chronyc -a makestep || true

# 等待同步完成
sleep 5

chronyc tracking
chronyc sources -v
sudo timedatectl status


log "Installing K3S agent..."

export K3S_TOKEN="$(cat /home/debian/k3s-token)"
export K3S_URL="https://192.168.6.1:${K3S_API_PORT}"
export K3S_NODE_NAME="bbb-agent"

curl -sfL https://get.k3s.io | sh -s - agent