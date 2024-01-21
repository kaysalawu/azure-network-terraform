#!/bin/bash

echo "Resource Group: $1"
echo "VPN Gateway Name: $2"

if [ $# -ne 2 ] || [ "$1" == "-h" ] || [ "$1" == "--helper" ]; then
    echo -e "\nUsage: $0 RESOURCE_GROUP_NAME VPN_GATEWAY_NAME\n"
    return 1
fi

curl $(az network vnet-gateway vpn-client generate \
--resource-group $1 \
--name $2 \
--authentication-method EAPTLS | tr -d '"') --output ./vpnClient.zip
unzip vpnClient.zip -d vpnClient

VPN_CLIENT_CERT=$(awk '{printf "%s\\n", $0}' ./*_cert.pem)
VPN_CLIENT_KEY=$(awk '{printf "%s\\n", $0}' ./*_key.pem)

sed -i "s~\$CLIENTCERTIFICATE~$VPN_CLIENT_CERT~" "./vpnClient/OpenVPN/vpnconfig.ovpn"
sed -i "s~\$PRIVATEKEY~$VPN_CLIENT_KEY~g" "./vpnClient/OpenVPN/vpnconfig.ovpn"

echo "sudo openvpn --config ./vpnClient/OpenVPN/vpnconfig.ovpn"
sudo openvpn --config ./vpnClient/OpenVPN/vpnconfig.ovpn &
sleep 3
echo "ps aux | grep "[o]penvpn""
ps aux | grep "[o]penvpn"
