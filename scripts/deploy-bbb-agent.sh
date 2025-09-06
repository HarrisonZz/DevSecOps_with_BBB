#!/bin/bash

readonly BBB_HOST="${1:-192.168.6.2}"  # BBB IP 位址
readonly BBB_USER="${2:-debian}"          # BBB 使用者
readonly K3S_SERVER_IP="192.168.20.11"   # K3S Server IP
readonly K3S_API_PORT="400"              # K3S API Port (修正為標準埠)
readonly SSH_KEY="${HOME}/.ssh/id_rsa"    # SSH 私鑰路徑

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# SSH 執行函數
ssh_execute() {
    local command="$1"
    local description="$2"
    
    log "Executing: $description"
    ssh -i "$SSH_KEY" \
        -o StrictHostKeyChecking=no \
        -o ConnectTimeout=10 \
        -o BatchMode=yes \
        "$BBB_USER@$BBB_HOST" \
        "$command" || error_exit "Failed: $description"
}

# 檢查 SSH 連接
verify_ssh_connection() {
    log "Verifying SSH connection to $BBB_HOST..."
    
    if ! ssh -i "$SSH_KEY" \
            -o StrictHostKeyChecking=no \
            -o ConnectTimeout=10 \
            -o BatchMode=yes \
            "$BBB_USER@$BBB_HOST" \
            "echo 'SSH connection successful'" &>/dev/null; then
        error_exit "SSH connection to $BBB_HOST failed"
    fi
    
    log "SSH connection verified"
}

# 獲取 K3S token
get_k3s_token() {
    log "Retrieving K3S node token..."
    
    if [[ -f /var/lib/rancher/k3s/server/node-token ]]; then
        cat /var/lib/rancher/k3s/server/node-token
    else
        error_exit "K3S node token not found"
    fi
}

# 部署 BBB agent
deploy_bbb_agent() {
    local k3s_token="$1"
    
    log "Starting BBB K3S agent deployment..."
    
    # 1. 設定 DNS resolver
    log "Configuring DNS settings..."
    ssh_execute "
        echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf
        echo 'nameserver 8.8.4.4' | sudo tee -a /etc/resolv.conf
    " "DNS configuration"
    
    # 2. 網路配置
    log "Configuring network interfaces..."
    ssh_execute "
        sudo dhclient usb0 || true
        sudo ip route add 192.168.20.0/24 via 192.168.6.1 dev usb1 || true
    " "Network configuration"
    
    # 3. 時間同步設定
    log "Configuring time synchronization..."
    ssh_execute "
        # 建立 chrony 設定
        sudo tee /etc/chrony/chrony.conf << 'EOF'
server $K3S_SERVER_IP iburst
makestep 1.0 3
driftfile /var/lib/chrony/chrony.drift
rtcsync
allow 192.168.6.0/24
EOF
        
        # 重新啟動服務
        sudo systemctl restart chronyd
        sudo systemctl enable chronyd
        sudo systemctl disable --now systemd-timesyncd || true
        
        # 強制時間同步
        sudo chronyc -a makestep || true
        
        # 等待同步完成
        sleep 5
    " "Time synchronization setup"
    
    # 4. 驗證時間同步
    log "Verifying time synchronization..."
    ssh_execute "
        chronyc tracking
        chronyc sources -v
        sudo timedatectl status
    " "Time sync verification"
    
    # 5. 測試 K3S API 連接
    log "Testing K3S API connectivity..."
    ssh_execute "
        curl -k --connect-timeout 10 https://192.168.6.1:$K3S_API_PORT/ping || 
        curl -k --connect-timeout 10 https://$K3S_SERVER_IP:$K3S_API_PORT/ping
    " "K3S API connectivity test"
    
    # 6. 安裝 K3S agent
    log "Installing K3S agent..."
    ssh_execute "
        export K3S_TOKEN='$k3s_token'
        export K3S_URL='https://192.168.6.1:$K3S_API_PORT'
        export K3S_NODE_NAME='bbb-agent-\$(hostname -s)'
        
        curl -sfL https://get.k3s.io | sh -s - agent
    " "K3S agent installation"
    
    # 7. 驗證 agent 狀態
    log "Verifying K3S agent status..."
    ssh_execute "
        sudo systemctl status k3s-agent --no-pager
        sudo systemctl is-active k3s-agent
    " "K3S agent status verification"
    
    log "BBB K3S agent deployment completed successfully!"
}

# 主要執行流程
main() {
    log "=== BBB K3S Agent Deployment Started ==="
    
    # 檢查必要檔案
    [[ -f "$SSH_KEY" ]] || error_exit "SSH key not found: $SSH_KEY"
    
    # 驗證 SSH 連接
    verify_ssh_connection
    
    # 獲取 K3S token
    local k3s_token
    k3s_token=$(get_k3s_token)
    
    # 執行部署
    deploy_bbb_agent "$k3s_token"
    
    log "=== Deployment Completed ==="
    
    # 在 K3S server 上驗證節點狀態
    log "Verifying node registration..."
    sleep 10
    kubectl get nodes || log "Warning: Unable to verify nodes"
    
    log "Use 'kubectl get nodes' to verify the new agent node"
}

# 執行主程式
main "$@"