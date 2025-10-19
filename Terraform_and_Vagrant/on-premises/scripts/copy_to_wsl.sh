#!/bin/bash


PROJECT_DIR="$(pwd)"

mkdir -p ~/.ssh
cp "$PROJECT_DIR/.ssh_config" ~/.ssh/vagrant_config
chmod 600 ~/.ssh/vagrant_config

for vm in "$@"; do
  KEY_SRC="$PROJECT_DIR/.vagrant/machines/$vm/vmware_desktop/private_key"
  KEY_DEST="$HOME/.ssh/${vm}_key"

  cp "$KEY_SRC" "$KEY_DEST"
  chmod 600 "$KEY_DEST"
done
