#!/bin/bash

LOG_FILE="/var/log/ipsec-vti.log"

IP=$(which ip)
IPTABLES=$(which iptables)

PLUTO_MARK_OUT_ARR=($${PLUTO_MARK_OUT//// })
PLUTO_MARK_IN_ARR=($${PLUTO_MARK_IN//// })

case "$PLUTO_CONNECTION" in
%{~ for v in TUNNELS }
  ${v.name})
    VTI_INTERFACE=${v.name}
    VTI_LOCALADDR=${v.vti_local_addr}
    VTI_REMOTEADDR=${v.vti_remote_addr}
    ;;
%{~ endfor }
esac

echo "$(date): Trigger - CONN=$${PLUTO_CONNECTION}, VERB=$${PLUTO_VERB}, ME=$${PLUTO_ME}, PEER=$${PLUTO_PEER}], PEER_CLIENT=$${PLUTO_PEER_CLIENT}, MARK_OUT=$${PLUTO_MARK_OUT_ARR}, MARK_IN=$${PLUTO_MARK_IN_ARR}" >> $LOG_FILE

case "$PLUTO_VERB" in
  up-client)
    $IP link add $${VTI_INTERFACE} type vti local $${PLUTO_ME} remote $${PLUTO_PEER} okey $${PLUTO_MARK_OUT_ARR[0]} ikey $${PLUTO_MARK_IN_ARR[0]}
    sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.disable_policy=1
    sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.rp_filter=2 || sysctl -w net.ipv4.conf.$${VTI_INTERFACE}.rp_filter=0
    $IP addr add $${VTI_LOCALADDR} remote $${VTI_REMOTEADDR} dev $${VTI_INTERFACE}
    $IP link set $${VTI_INTERFACE} up mtu 1436
    $IPTABLES -t mangle -I FORWARD -o $${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    $IPTABLES -t mangle -I INPUT -p esp -s $${PLUTO_PEER} -d $${PLUTO_ME} -j MARK --set-xmark $${PLUTO_MARK_IN}
    $IP route flush table 220
    #/etc/init.d/bgpd reload || /etc/init.d/quagga force-reload bgpd
    ;;
  down-client)
    $IP link del $${VTI_INTERFACE}
    $IPTABLES -t mangle -D FORWARD -o $${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    $IPTABLES -t mangle -D INPUT -p esp -s $${PLUTO_PEER} -d $${PLUTO_ME} -j MARK --set-xmark $${PLUTO_MARK_IN}
    ;;
esac

# github source used
# https://gist.github.com/heri16/2f59d22d1d5980796bfb
