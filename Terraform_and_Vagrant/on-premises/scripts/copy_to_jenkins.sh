#!/bin/bash


PROJECT_DIR="$(pwd)"
JENKINS_HOME="/var/lib/jenkins"
SSH_DIR="$JENKINS_HOME/.ssh"

sudo cp "$PROJECT_DIR/.ssh_config" $JENKINS_HOME/.ssh/vagrant_config
sudo chmod 600 $JENKINS_HOME/.ssh/vagrant_config

for vm in "$@"; do
  KEY_SRC="$PROJECT_DIR/.vagrant/machines/$vm/vmware_desktop/private_key"
  KEY_DEST="$JENKINS_HOME/.ssh/${vm}_key"

  sudo cp "$KEY_SRC" "$KEY_DEST"
  sudo chmod 600 "$KEY_DEST"
done

sudo chown -R jenkins:jenkins "$SSH_DIR"