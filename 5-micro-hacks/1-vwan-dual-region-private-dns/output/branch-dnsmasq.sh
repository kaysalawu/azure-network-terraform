#!/bin/bash

# disable systemd-resolved as it conflicts with dnsmasq on port 53

systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "$(hostname -I | cut -d' ' -f1) $(hostname)" >> /etc/hosts

# install dnsmasq and tools
apt update
apt install -y dnsmasq dnsutils net-tools

sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp

# Enable logging in dnsmasq
echo "log-facility=/var/log/dnsmasq.log" >> /etc/dnsmasq.conf
echo "log-queries" >> /etc/dnsmasq.conf

# Ensure log file exists and set appropriate permissions
touch /var/log/dnsmasq.log
chmod 644 /var/log/dnsmasq.log

# configure dnsmasq local zone records
cat <<EOF >> /etc/dnsmasq.d/local_records.conf
address=/vm.branch1.corp/10.10.0.5
address=/vm.branch2.corp/10.30.0.5
EOF
# configure dnsmasq forwarding zones
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
systemctl enable dnsmasq
systemctl restart dnsmasq
apt install resolvconf
resolvconf -u
