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

# configure dnsmasq forwarding zones
cat <<EOF >> /etc/dnsmasq.d/forwarding.conf
server=/./168.63.129.16
EOF
systemctl enable dnsmasq
systemctl restart dnsmasq
apt install resolvconf
resolvconf -u
