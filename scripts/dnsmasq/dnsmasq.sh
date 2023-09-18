#!/bin/bash

apt update
apt install -y tcpdump dnsmasq resolvconf dnsutils net-tools

sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp
systemctl stop systemd-resolved
systemctl disable systemd-resolved
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

cat <<EOL > /etc/dnsmasq.d/local_records.conf
%{~ for tuple in ONPREM_LOCAL_RECORDS }
address=/"${tuple.name}/${tuple.record}
%{~ endfor ~}
EOL

cat <<EOL > /etc/dnsmasq.d/forwarding.conf
%{~ for tuple in FORWARD_ZONES }
%{~ for target in tuple.targets }
server=/${tuple.zone}/10.11.5.4
%{~ endfor ~}
%{~ endfor ~}
EOL

systemctl restart dnsmasq
systemctl enable dnsmasq
