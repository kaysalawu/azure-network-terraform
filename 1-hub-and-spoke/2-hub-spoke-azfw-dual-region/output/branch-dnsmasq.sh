#!/bin/bash

systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8 > /etc/resolv.conf"

apt update
apt install -y dnsmasq dnsutils net-tools

sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp

# local data records
cat <<EOF >> /etc/dnsmasq.d/local_records.conf
address=/vm.branch1.corp/10.10.0.5
address=/vm.branch2.corp/10.20.0.5
address=/vm.branch3.corp/10.30.0.5
EOF

# dns forwarding
cat <<EOF >> /etc/dnsmasq.d/forwarding.conf
server=/az.corp./10.11.8.4
server=/az.corp./10.22.8.4
server=/az.corp./10.11.8.4
server=/az.corp./10.22.8.4
server=/privatelink.blob.core.windows.net./10.11.8.4
server=/privatelink.blob.core.windows.net./10.22.8.4
server=/privatelink.azurewebsites.net./10.11.8.4
server=/privatelink.azurewebsites.net./10.22.8.4
server=/privatelink.database.windows.net./10.11.8.4
server=/privatelink.database.windows.net./10.22.8.4
server=/privatelink.table.cosmos.azure.com./10.11.8.4
server=/privatelink.table.cosmos.azure.com./10.22.8.4
server=/privatelink.queue.core.windows.net./10.11.8.4
server=/privatelink.queue.core.windows.net./10.22.8.4
server=/privatelink.file.core.windows.net./10.11.8.4
server=/privatelink.file.core.windows.net./10.22.8.4
server=/./168.63.129.16
EOF

systemctl restart dnsmasq
systemctl enable dnsmasq

# apt install resolvconf
# resolvconf -u
