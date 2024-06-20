#! /bin/bash

exec > /var/log/azure-setup-unbound.log

systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "$(hostname -I | cut -d' ' -f1) $(hostname)" | tee -a /etc/hosts >/dev/null
mkdir -p /etc/unbound
touch /etc/unbound/unbound.log && chmod a+x /etc/unbound/unbound.log
apt-get install -y resolvconf
