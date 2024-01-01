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

%{~ if ONPREM_LOCAL_RECORDS != [] }
# configure dnsmasq local zone records
cat <<EOF >> /etc/dnsmasq.d/local_records.conf
%{~ for tuple in ONPREM_LOCAL_RECORDS }
address=/${tuple.name}/${tuple.record}
%{~ endfor }
EOF
%{~ endif ~}

%{~ if FORWARD_ZONES != [] }
# configure dnsmasq forwarding zones
cat <<EOF >> /etc/dnsmasq.d/forwarding.conf
%{~ for tuple in FORWARD_ZONES }
%{~ for target in tuple.targets }
server=/${tuple.zone}/${target}
%{~ endfor ~}
%{~ endfor }
EOF
%{~ endif ~}

systemctl enable dnsmasq
systemctl restart dnsmasq
apt install resolvconf
resolvconf -u
