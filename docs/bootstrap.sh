#!/bin/bash
set -x
echo $0
SCRIPT=`readlink -f -- $0`
SCRIPTPATH=`dirname $SCRIPT`

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit -1
fi
FQDN=${SERVERNAME}.${DOMAIN}
SERVER_IP=$(echo $SSH_CONNECTION | cut -d ' ' -f 3)

function add_host() {

    if ! fgrep -q ${SERVER_IP} /etc/hosts ; then
        echo Adding $SERVER_IP $FQDN to /etc/hosts
        echo $SERVER_IP ${FQDN} ${SERVERNAME} >> /etc/hosts
    fi

    if [ ! $(hostname -f)  != "$FQDN" ]; then
        echo Setting hostname to $SERVERNAME
        echo ${SERVERNAME} > /etc/hostname

        hostnamectl set-hostname ${FQDN}
    fi
}
function add_ansible_user() {
    # Set up ansible user
    useradd -rm ansible
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
    chmod 440 /etc/sudoers.d/ansible
    mkdir -m 700 /home/ansible/.ssh
    #echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsW/fNKMjMQjkYcQOqwD14UItgMBGIX7HHpP2YTvQkI ansible" > /home/ansible/.ssh/authorized_keys
    wget https://thr27.github.io/la-cuna-icu/authorized_keys2 -O /home/ansible/.ssh/authorized_keys2
    chmod 600 /home/ansible/.ssh/authorized_keys
    chown -R ansible.ansible /home/ansible/.ssh
}