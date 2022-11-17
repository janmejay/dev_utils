#!/bin/bash

cmd=$1

vpn_gw_ip=$2
if [ -z $vpn_gw_ip ]; then
    echo "VPN GW IP addr is required (NAT isn't supported)"
    exit 1
fi
vpn_ssh_host=janmejay@$vpn_gw_ip
tun_iface=${3:-pj0}

egress_route=$(ip route get $vpn_gw_ip)

egress_ip=$(echo $egress_route | grep -Po 'src [^ ]+' | sed -re 's/src //g')
egress_link=$(echo $egress_route | grep -Po 'dev [^ ]+' | sed -re 's/dev //g')

peer_egress_route=$(ssh $vpn_ssh_host "ip route get ${egress_ip}")

refresh_script=/tmp/refresh.route.sh
function refresh {
  if [ -s $refresh_script ]; then
    sudo /bin/bash $refresh_script
  fi
}

return_rule="-d ${vpn_gw_ip} -j ACCEPT"
onward_rule="-s ${vpn_gw_ip} -j ACCEPT"

insert_cmd="sudo iptables -t filter -I FORWARD 1"
drop_cmd="sudo iptables -t filter -D FORWARD"

case $cmd in
  on)
    $0 off $vpn_gw_ip
    echo "On..."
    ssh $vpn_ssh_host "ip route show | grep $tun_iface" \
        | sed -r \
              -e "s/${tun_iface}/$egress_link/g" \
              -e "s/via [^ ]+/via ${vpn_gw_ip}/g" \
              -e 's/^/sudo ip route add /g' \
        | grep -v link \
        | tee $refresh_script
    refresh

    ssh -t $vpn_ssh_host \
        "${insert_cmd} ${onward_rule}; ${insert_cmd} ${return_rule}"
    ;;
  off)
    echo "Off..."
    ip route show \
        | grep -F "via ${vpn_gw_ip}" \
        | sed -re 's/^/ip route del /g' \
        | tee $refresh_script

    refresh
    ssh -t $vpn_ssh_host \
        "${drop_cmd} ${onward_rule}; ${drop_cmd} ${return_rule}"
    ;;
esac
