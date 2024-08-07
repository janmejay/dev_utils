#!/usr/bin/env bash

sudo ipset list blacklist 1>/dev/null 2>&1

if [ $? -ne 0 ]; then
    sudo ipset create blacklist hash:ip hashsize 4096
    sudo iptables -A OUTPUT -m set --match-set blacklist dst -j REJECT
fi

sudo ipset flush blacklist

def_gw=$(ip route show default | grep -Eo 'via [0-9.]+' | awk '{print $NF}')
dns_servers="$def_gw 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220"

for h in $*; do
    for d in $dns_servers; do
        dig A +short @$d $h | \
            grep -E '^[0-9.]+$'
    done
done | \
    sort | \
    uniq | \
    xargs -n1 sudo ipset add blacklist 2>/dev/null

