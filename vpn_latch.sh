#!/usr/bin/env bash

cmd=$1

vpn_gw_ip=$2
set -x
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
    sudo /usr/bin/env bash $refresh_script
  fi
}

return_rule="-d ${egress_ip} -j ACCEPT"
onward_rule="-s ${egress_ip} -j ACCEPT"
nat_rule="-s ${egress_ip} -o ${tun_iface} -j MASQUERADE"

insert_filt="iptables -t filter -I FORWARD 1"
drop_filt="iptables -t filter -D FORWARD"
insert_nat="iptables -t nat -I POSTROUTING 1"
drop_nat="iptables -t nat -D POSTROUTING"

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

    ins_frag="${insert_nat} ${nat_rule};"
    ins_frag+="${insert_filt} ${onward_rule};"
    ins_frag+="${insert_filt} ${return_rule};"
    ssh -t $vpn_ssh_host "sudo /usr/bin/env bash -c '${ins_frag}'"
    ssh $vpn_ssh_host "cat /etc/dnsmasq.d/vpn.conf" | sudo tee /etc/dnsmasq.d/vpn.conf
    sudo systemctl restart dnsmasq
    ;;
  off)
    echo "Off..."
    ip route show \
        | grep -F "via ${vpn_gw_ip}" \
        | sed -re 's/^/ip route del /g' \
        | tee $refresh_script

    refresh

    drop_frag="${drop_nat} ${nat_rule}; "
    drop_frag+="${drop_filt} ${onward_rule};"
    drop_frag+="${drop_filt} ${return_rule}"
    ssh -t $vpn_ssh_host "sudo /usr/bin/env bash -c '${drop_frag}'"
    ;;
  try)
      ssh $vpn_ssh_host "ip route show | grep $tun_iface"
esac
