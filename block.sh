#!/bin/bash

sudo ipset list blacklist 1>/dev/null 2>&1

if [ $? -ne 0 ]; then
    sudo ipset create blacklist hash:ip hashsize 4096
    sudo iptables -A OUTPUT -m set --match-set blacklist dst -j REJECT
fi

sudo ipset flush blacklist

for h in $*; do
    dig A +short $h | xargs -n1 sudo ipset add blacklist 
done

