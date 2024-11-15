#!bin/bash

SERVERNAME=${SERVERNAME:-server1}
DOMAIN=${DOMAIN:-la-cuna.icu}

if [ f $SCRIPTPATH/bootstrap.sh ]; then
  source $SCRIPTPATH/bootstrap.sh
else
  if [ ! -f /tmp/bootstrap.sh ] ; then
    wget https://thr27.github.io/la-cuna-icu-bootstrap/bootstrap.sh -O /tmp/bootstrap.sh
  fi
  source /tmp/bootstrap.sh
fi

# Check if functions are defined before calling them
if declare -f add_host > /dev/null && declare -f add_ansible > /dev/null; then
  add_host
  add_ansible
else
  echo "Functions add_host and/or add_ansible are not defined. Bootsrap script not found or failed ..."
fi