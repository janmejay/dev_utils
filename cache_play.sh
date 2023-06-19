#!/bin/bash

want=${1:on}

function finish_up {
    sudo rc-service dnsmasq restart
    nslookup repository.rubrik.com
    ssh sdmain1 'sudo pkill sleep'
}

if [ $want == 'on' ]; then
    sudo sed -re 's/^[# ]*//g' -i /etc/dnsmasq.d/caching.conf
    finish_up
elif [ $want == 'off' ]; then
    sudo sed -re 's/^/#/g' -i /etc/dnsmasq.d/caching.conf
    finish_up
else
    echo "Unknown desired state: $want"
    exit 1
fi
