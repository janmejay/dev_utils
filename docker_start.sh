#!/usr/bin/env bash

sudo rc-service docker start

docker_gw_ip=$(
    ip addr \
        | grep docker0 \
        | grep inet \
        | awk '{print $2}' \
        | sed -re 's#/.+##g')

function container_up {
    sudo docker start $1
    sudo docker exec $1 /usr/sbin/sshd
    sudo docker exec $1 \
         /usr/bin/sudo \
         /bin/bash -c "echo 'nameserver $docker_gw_ip' > /etc/resolv.conf"
}

container_name=${1:-cdm_sdmain6}

container_up $container_name
