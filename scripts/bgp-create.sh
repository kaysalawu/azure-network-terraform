#!/bin/bash

az network vhub bgpconnection create \
--resource-group ${RG} \
--vhub-name ${VHUB_NAME} \
--name ${NAME} \
--peer-asn ${PEER_ASN} \
--peer-ip ${PEER_IP} \
--vhub-conn ${VHUB_CONN} #\
#--no-wait
