#!/bin/sh
chmod +x util/op-get-password.sh
ansible-playbook site.yml --vault-password-file util/op-get-password.sh "$@"
