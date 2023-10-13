#!/bin/bash

apt update
apt install -y dnsmasq dnsutils net-tools

sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.bkp

cat <<EOF >> /etc/dnsmasq.d/local_records.conf
%{~ for tuple in ONPREM_LOCAL_RECORDS }
address=/${tuple.name}/${tuple.record}
%{~ endfor }
EOF

cat <<EOF >> /etc/dnsmasq.d/forwarding.conf
%{~ for tuple in FORWARD_ZONES }
%{~ for target in tuple.targets }
server=/${tuple.zone}/${target}
%{~ endfor ~}
%{~ endfor }
EOF

systemctl stop systemd-resolved
systemctl disable systemd-resolved

sleep 120
systemctl restart dnsmasq
systemctl enable dnsmasq

apt install resolvconf
resolvconf -u
