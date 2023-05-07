#!/bin/bash
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# playbook is first arg but defaults to site.yml if not specified
if [ ! -z "$1" ]; then
  PLAYBOOK=$1
  ARGS=${2-}
else
  PLAYBOOK="site.yml"
  ARGS=${1-}
fi

cd "$SCRIPTPATH"
chmod +x util/op-get-password.sh
ansible-playbook "$PLAYBOOK" --vault-password-file util/op-get-password.sh $ARGS
