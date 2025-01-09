#!/bin/bash
#set -x
echo $0
SCRIPT=`readlink -f -- $0`
SCRIPTPATH=`dirname $SCRIPT`

if [ "$EUID" -ne 0 ]
	then echo "Please run as root"
	exit -1
fi
FQDN=${SERVERNAME}.${DOMAIN}
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(echo $SSH_CONNECTION | cut -d ' ' -f 3)

    if [ -z "$SERVER_IP" ] ; then
        SERVER_IP=$(ip addr show |grep -E 'scope global dynamic|scope global eth0' | grep 'inet ' |head -1| awk '{print $2}' | cut -d'/' -f1)
    fi
fi

if [ -z "$SERVERNAME" ] || [ -z "$DOMAIN" ] || [ -z "$SERVER_IP" ] ; then
    echo "Failed: Missing required variables SERVERNAME=$SERVERNAME,  DOMAIN=$DOMAIN or SERVER_IP=$SERVER_IP"
    exit 1
fi

function add_host() {

    if ! fgrep -q ${SERVER_IP} /etc/hosts ; then
        echo Adding $SERVER_IP $FQDN to /etc/hosts
        echo $SERVER_IP ${FQDN} ${SERVERNAME} >> /etc/hosts
    fi

    if [ ! $(hostname -f 2>/dev/null)  != "$FQDN" ]; then
        echo Setting hostname to $SERVERNAME
        echo ${SERVERNAME} > /etc/hostname

        hostnamectl hostname ${FQDN}
    fi
}
function add_ansible_user() {
    # Set up ansible user
    useradd -rm ansible
    echo "ansible ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ansible
    chmod 440 /etc/sudoers.d/ansible
    mkdir -p -m 700 /home/ansible/.ssh
    #echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsW/fNKMjMQjkYcQOqwD14UItgMBGIX7HHpP2YTvQkI ansible" > /home/ansible/.ssh/authorized_keys
    wget https://thr27.github.io/la-cuna-icu-bootstrap/authorized_keys -O /home/ansible/.ssh/authorized_keys
    chmod 600 /home/ansible/.ssh/authorized_keys
    chown -R ansible:ansible /home/ansible/.ssh

    [ ! -f ~/.ssh/authorized_keys ] && touch ~/.ssh/authorized_keys
    # Check if authorized_keys content is in user's authorized_keys
    if ! grep -q -F -x -f /home/ansible/.ssh/authorized_keys ~/.ssh/authorized_keys; then
        cat /home/ansible/.ssh/authorized_keys >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    fi
}