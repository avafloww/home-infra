#!/bin/sh
# on the ansible management host, we get the vault password from a local file
# this file is only accessible to root, so we need to use sudo to read it
if [ -f "/opt/ansible/vault-password" ]; then
    sudo cat /opt/ansible/vault-password && exit 0
fi

# Get the Ansible Vault password from 1Password vault
op item get j2hjpgat7caqs37rknafoirmru --fields label=password
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get Ansible Vault password from 1Password"
    exit 1
fi
