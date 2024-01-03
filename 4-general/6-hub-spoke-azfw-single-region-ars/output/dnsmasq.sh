#!/bin/bash

apt update
apt install -y tcpdump dnsmasq resolvconf dnsutils net-tools

sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp
systemctl stop systemd-resolved
systemctl disable systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

cat <<EOL > /etc/dnsmasq.d/local_records.conf
address=/"vm.branch1.corp/10.10.0.5
address=/"vm.branch2.corp/10.20.0.5
address=/"vm.branch3.corp/10.30.0.5EOL

cat <<EOL > /etc/dnsmasq.d/forwarding.conf
server=/az.corp./10.11.5.4
server=/./10.11.5.4EOL

systemctl restart dnsmasq
systemctl enable dnsmasq
