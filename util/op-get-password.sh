#!/bin/sh
# Get the Ansible Vault password from 1Password vault
op item get j2hjpgat7caqs37rknafoirmru --fields label=password
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to get Ansible Vault password from 1Password"
    exit 1
fi
