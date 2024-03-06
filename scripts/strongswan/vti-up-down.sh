#!/bin/bash

LOG_FILE="/var/log/vti-up-down.log"

IP=$(which ip)
IPTABLES=$(which iptables)

PLUTO_MARK_OUT_ARR=($${PLUTO_MARK_OUT//// })
PLUTO_MARK_IN_ARR=($${PLUTO_MARK_IN//// })

case "$PLUTO_CONNECTION" in
%{~ for v in TUNNELS }
  ${v.name})
    VTI_INTERFACE=${v.vti_name}
    VTI_LOCAL_ADDR=${v.vti_local_addr}
    ;;
%{~ endfor }
esac

echo "$(date): Trigger - CONN=$${PLUTO_CONNECTION}, VERB=$${PLUTO_VERB}, ME=$${PLUTO_ME}, PEER=$${PLUTO_PEER}], PEER_CLIENT=$${PLUTO_PEER_CLIENT}, MARK_OUT=$${PLUTO_MARK_OUT_ARR}, MARK_IN=$${PLUTO_MARK_IN_ARR}" >> $LOG_FILE

case "$PLUTO_VERB" in
  up-client)
    $IP link add $${VTI_INTERFACE} type vti local $${PLUTO_ME} remote $${PLUTO_PEER} okey $${PLUTO_MARK_OUT_ARR[0]} ikey $${PLUTO_MARK_IN_ARR[0]}
    $IP link set $${VTI_INTERFACE} up
    $IP addr add $${VTI_LOCAL_ADDR} dev $${VTI_INTERFACE}
    #$IP route add $${PLUTO_PEER_CLIENT} dev $${VTI_INTERFACE}
    ;;
  down-client)
    $IP route del $${PLUTO_PEER_CLIENT} dev $${VTI_INTERFACE}
    $IP link del $${VTI_INTERFACE}
    ;;
esac
