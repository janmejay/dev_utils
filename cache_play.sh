#!/usr/bin/env bash

want=${1:on}

function finish_up {
    sudo systemctl restart dnsmasq
    nslookup repository.rubrik.com
    ssh sdmain1 'sudo pkill sleep'
}

if [ $want == 'on' ]; then
    sudo sed -re 's/^[# ]*//g' -i /etc/dnsmasq.d/caching.conf
    sudo iptables -t nat -I PREROUTING -d 172.17.0.1/32 -p tcp --dport 80 -j REDIRECT --to-ports 12080
    sudo iptables -t nat -I PREROUTING -d 172.17.0.1/32 -p tcp --dport 443 -j REDIRECT --to-ports 12443
    finish_up
elif [ $want == 'off' ]; then
    sudo sed -re 's/^/#/g' -i /etc/dnsmasq.d/caching.conf
    sudo iptables -t nat -D PREROUTING -d 172.17.0.1/32 -p tcp --dport 80 -j REDIRECT --to-ports 12080
    sudo iptables -t nat -D PREROUTING -d 172.17.0.1/32 -p tcp --dport 443 -j REDIRECT --to-ports 12443
    finish_up
else
    echo "Unknown desired state: $want"
    exit 1
fi
