#!/bin/bash
# playbook is first arg but defaults to site.yml if not specified
if [ ! -z "$1" ]; then
  PLAYBOOK=$1
  ARGS=${2-}
else
  PLAYBOOK="site.yml"
  ARGS=${1-}
fi

chmod +x util/op-get-password.sh
ansible-playbook "$PLAYBOOK" --vault-password-file util/op-get-password.sh $ARGS
