#!/bin/bash

#systemctl stop systemd-resolved
#systemctl disable systemd-resolved

apt update
apt install -y dnsmasq dnsutils net-tools

sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp

cat <<EOL >> /etc/dnsmasq.d/local_records.conf
%{~ for tuple in ONPREM_LOCAL_RECORDS }
address=/${tuple.name}/${tuple.record}
%{~ endfor }
EOL

cat <<EOL >> /etc/dnsmasq.d/forwarding.conf
%{~ for tuple in FORWARD_ZONES }
%{~ for target in tuple.targets }
server=/${tuple.zone}/10.11.5.4
%{~ endfor ~}
%{~ endfor ~}
EOL

systemctl restart dnsmasq
systemctl enable dnsmasq

apt install resolvconf
resolvconf -u
