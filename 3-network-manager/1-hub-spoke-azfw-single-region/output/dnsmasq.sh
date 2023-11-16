#!/bin/bash

#systemctl stop systemd-resolved
#systemctl disable systemd-resolved

apt update
apt install -y dnsmasq dnsutils net-tools

sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp

cat <<EOL >> /etc/dnsmasq.d/local_records.conf
address=/vm.branch1.corp/10.10.0.5
address=/vm.branch2.corp/10.20.0.5
address=/vm.branch3.corp/10.30.0.5
EOL

cat <<EOL >> /etc/dnsmasq.d/forwarding.conf
server=/az.corp./10.11.5.4
server=/./10.11.5.4EOL

systemctl restart dnsmasq
systemctl enable dnsmasq

apt install resolvconf
resolvconf -u
