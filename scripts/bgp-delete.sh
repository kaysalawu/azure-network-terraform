#!/bin/bash

az network vhub bgpconnection delete \
--resource-group ${RG} \
--vhub-name ${VHUB_NAME} \
--name ${NAME} \
--yes #\
#--no-wait
