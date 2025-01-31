#!/usr/bin/env bash

if [ $(whoami) != 'root' ]; then
    echo "ssh root@localhost and then run this script"
fi

set -x

default_dests='172.50.24.143/32,172.50.17.41/32'
default_tun_gw='10.0.14.86' # colo-dev vm' dev host0
default_tun_spec='0:0'
default_nw='192.168.4.0/30'
default_gw_nw_ip_nw='192.168.4.1/30'
default_local_nw_ip_nw='192.168.4.2/30'

ip_addr=${1:-$default_dests}
tun_gw=${2:-$default_tun_gw}
tun_spec=${3:-$default_tun_spec}
nw=${4:-$default_nw}
gw_ip_nw=${5:-$default_gw_nw_ip_nw}
local_ip_nw=${6:-$default_local_nw_ip_nw}

gw_tun_dev=$(echo $tun_spec | sed -re 's/.+:/tun/')
local_tun_dev=$(echo $tun_spec | sed -re 's/:.+//g' -e 's/^/tun/')

ssh -w$tun_spec root@$tun_gw 'sleep 123456789' &

trap "kill $(jobs -p)" EXIT

while : ; do
  echo "Awaiting tunnel $local_tun_dev ..."
  ip link show | grep -qP "^\d+: $local_tun_dev:"
  if [ $? -eq 0 ]; then
    break
  fi
  sleep 1
done

ssh root@$tun_gw <<EOF
  set -x
  echo 1 > tee /proc/sys/net/ipv4/ip_nonlocal_bind
  echo 1 > tee /proc/sys/net/ipv4/ip_forward
  echo $ip_addr | \
    sed -re 's/,/ /g' | \
    xargs -n1 ip route get | \
    grep -Po 'dev [^ ]+' | \
    awk '{print \$2}' | \
    sort | \
    uniq | \
    xargs -n1 -I% iptables -t nat -I POSTROUTING 1 -s $nw -o % -j MASQUERADE
 iptables -t filter -I FORWARD 1 -d $nw -j ACCEPT
 iptables -t filter -I FORWARD 1 -s $nw -j ACCEPT
 ip link set up $gw_tun_dev
 ip addr add $gw_ip_nw dev $gw_tun_dev
EOF

gw_ip=$(echo $gw_ip_nw | sed -re 's#/.+$##')

ip link set up $local_tun_dev
ip addr add $local_ip_nw dev $local_tun_dev
ip route add $nw dev $local_tun_dev
echo $ip_addr | \
  sed -re 's/,/ /g' | \
  xargs -n1 | \
  xargs -I% ip route add % via $gw_ip

wait $(jobs -p)
