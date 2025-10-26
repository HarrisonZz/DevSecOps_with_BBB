#!/bin/bash
# scripts/copy_to_ci.sh

PROJECT_DIR="$(pwd)"
JENKINS_HOME="/var/lib/jenkins"

mkdir -p "$JENKINS_HOME/.ssh"
cp "$PROJECT_DIR/.ssh_config" "$JENKINS_HOME/.ssh/vagrant_config"
chmod 600 "$JENKINS_HOME/.ssh/vagrant_config"

for vm in "$@"; do
  KEY_SRC="$PROJECT_DIR/.vagrant/machines/$vm/vmware_desktop/private_key"
  KEY_DEST="$JENKINS_HOME/.ssh/${vm}_key"

  cp "$KEY_SRC" "$KEY_DEST"
  chmod 600 "$KEY_DEST"
done

chown -R jenkins:jenkins "$SSH_DIR"
