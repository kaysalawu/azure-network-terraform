#!/bin/bash

if [ "$#" -ne 2 ] || [ "$1" == "-h" ] || [ "$1" == "--helper" ]; then
    echo "Usage: $0 RESOURCE_GROUP_NAME VPN_GATEWAY_NAME"
    return 0
fi

RESOURCE_GROUP_NAME=$1
VPN_GATEWAY_NAME=$2

echo -e "\nchecking vnet gateway...\n"
curl $(az network vnet-gateway vpn-client generate \
--resource-group $RESOURCE_GROUP_NAME \
--name $VPN_GATEWAY_NAME \
--authentication-method EAPTLS | tr -d '"') --output ./vpnClient.zip

if [ $? -ne 0 ]; then
    echo -e "\nchecking vwan p2s gateway...\n"
    curl $(az network p2s-vpn-gateway vpn-client generate \
    --resource-group $RESOURCE_GROUP_NAME \
    --name $VPN_GATEWAY_NAME \
    --authentication-method EAPTLS 2>/dev/null | jq -r '.profileUrl') --output ./vpnClient.zip
fi

if [ $? -ne 0 ]; then
    return 1
fi

unzip vpnClient.zip -d vpnClient
rm vpnClient.zip

VPN_CLIENT_CERT=$(awk '{printf "%s\\n", $0}' ./*_cert.pem)
VPN_CLIENT_KEY=$(awk '{printf "%s\\n", $0}' ./*_key.pem)

sed -i "s~\$CLIENTCERTIFICATE~$VPN_CLIENT_CERT~" "./vpnClient/OpenVPN/vpnconfig.ovpn"
sed -i "s~\$PRIVATEKEY~$VPN_CLIENT_KEY~g" "./vpnClient/OpenVPN/vpnconfig.ovpn"
if [ -n "$VPN_GATEWAY_IP" ]; then
    sed -i "s/remote .* 443/remote $VPN_GATEWAY_IP 443/g" ./vpnClient/OpenVPN/vpnconfig.ovpn
fi

echo "sudo openvpn --config ./vpnClient/OpenVPN/vpnconfig.ovpn"
sudo openvpn --config ./vpnClient/OpenVPN/vpnconfig.ovpn &
sleep 3
echo "ps aux | grep "[o]penvpn""
ps aux | grep "[o]penvpn"
