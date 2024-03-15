#!/bin/sh

# exec > /var/log/linux-nva.log 2>&1

apt-get -y update
apt-get -y install sipcalc

#########################################################
# ip forwarding
#########################################################

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv4.conf.eth0.disable_xfrm=1
sysctl -w net.ipv4.conf.eth0.disable_policy=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# Disable ICMP redirects
# sysctl -w net.ipv4.conf.all.send_redirects=0
# sysctl -w net.ipv4.conf.all.accept_redirects=0
# sysctl -w net.ipv4.conf.eth0.send_redirects=0
# sysctl -w net.ipv4.conf.eth0.accept_redirects=0
# echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf
# echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
# echo "net.ipv4.conf.eth0.send_redirects=0" >> /etc/sysctl.conf
# echo "net.ipv4.conf.eth0.accept_redirects=0" >> /etc/sysctl.conf
# sysctl -p

#########################################################
# route table for eth1 (trust interface)
#########################################################

ETH1_DGW=$(sipcalc eth1 | awk '/Usable range/ {print $4}')
ETH1_MASK=$(ip addr show eth1 | awk '/inet / {print $2}' | cut -d'/' -f2)

# eth1 routing
echo "2 rt1" | tee -a /etc/iproute2/rt_tables

# ip rules
#-----------------------------------------------------
# ip rules tell the kernel which routing table to use.
# all traffic from/to eth1 subnet should use rt1 for lookup;
# an example is traffic to/from eth1 floating IP (load balcner VIP)
# the subnet mask expands the default GW IP to the entire subnet
ip rule add from $ETH1_DGW/$ETH1_MASK table rt1
ip rule add to $ETH1_DGW/$ETH1_MASK table rt1

# the azure user-defined routes will direct all vnet inbound traffic to eth1 (trust)
# if destination is internal (RFC1918 and RFC6598), ip rule directs kernel to use rt1 for lookup; and then use the ip routes in rt1
# if destination is internet (not RFC1918 and RFC6598), use the main routing table for lookup and exit via eth0 default gateway
# ip rule add to 10.0.0.0/8 table rt1
# ip rule add to 172.16.0.0/12 table rt1
# ip rule add to 192.168.0.0/16 table rt1
# ip rule add to 100.64.0.0/10 table rt1

# ip routes
#--------------------------------------------------
# kernel is directed to rt1 for RFC1918 and RFC6598 destinations
# the following default route is used for traffic forwarding via eth1
# ip route add 10.0.0.0/8 via $ETH1_DGW dev eth1 table rt1
# ip route add 172.16.0.0/12 via $ETH1_DGW dev eth1 table rt1
# ip route add 192.168.0.0/16 via $ETH1_DGW dev eth1 table rt1
# ip route add 100.64.0.0/10 via $ETH1_DGW dev eth1 table rt1

# for traffic originating from azure platform to eth1 ...
# rule "ip rule add to $ETH1_DGW/$ETH1_MASK table rt1" is used
# this rule directs that rt1 should be used for lookup
# the return traffic will use the following rt1 routes
ip route add 168.63.129.16/32 via $ETH1_DGW dev eth1 table rt1
# ip route add 169.254.169.254/32 via $ETH1_DGW dev eth1 table rt1

# alternatively, all the static routes can be replaced by a single default route
# ip route add default via $ETH1_DGW dev eth1 table rt1

#########################################################
# iptables
#########################################################

echo iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections
apt-get -y install iptables-persistent

# Permit flows on all chains (for testing only and not for production)
iptables -P FORWARD ACCEPT
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT

# Iptables rules
iptables -t nat -A POSTROUTING -d 10.0.0.0/8 -j ACCEPT
iptables -t nat -A POSTROUTING -d 172.16.0.0/12 -j ACCEPT
iptables -t nat -A POSTROUTING -d 192.168.0.0/16 -j ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
%{~ for rule in IPTABLES_RULES }
${rule}
%{~ endfor }

# Save to IPTables file for persistence on reboot
iptables-save > /etc/iptables/rules.v4

#########################################################
# packages
#########################################################

apt-get update
apt-get install -y strongswan frr

##  run the updates and ensure the packages are up to date and there is no new version available for the packages
#apt-get -y update --fix-missing
apt-get -y install tcpdump dnsutils traceroute tcptraceroute net-tools

sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
systemctl restart frr

#########################################################
# strongswan config
#########################################################

tee /etc/ipsec.conf <<'EOF'
${STRONGSWAN_IPSEC_CONF}
EOF

tee /etc/ipsec.secrets <<'EOF'
${STRONGSWAN_IPSEC_SECRETS}
EOF

tee /etc/ipsec.d/ipsec-vti.sh <<'EOF'
${STRONGSWAN_VTI_SCRIPT}
EOF
chmod a+x /etc/ipsec.d/ipsec-vti.sh

touch /var/log/ipsec-vti.log
systemctl restart ipsec.service

#########################################################
# frr  config
#########################################################

tee /etc/frr/frr.conf <<'EOF'
${FRR_CONF}
EOF

systemctl enable frr
systemctl restart frr

#########################################################
# test scripts
#########################################################

# ping-ip

cat <<EOF > /usr/local/bin/ping-ip
echo -e "\n ping ip ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo "${target.name} - ${target.ip} -\$(ping -qc2 -W1 ${target.ip} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo "${target.dns} - \$(dig +short ${target.dns} | tail -n1) -\$(ping -qc2 -W1 ${target.dns} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ip, "") != "" ~}
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.ip}) - ${target.name} (${target.ip})"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
%{ for target in TARGETS ~}
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.dns}) - ${target.dns}"
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
traceroute ${target.ip}
echo -e "${target.name}\n"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/trace-ip

# dns-info

cat <<EOF > /usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# ipsec debug

cat <<EOF > /usr/local/bin/ipsec-debug
echo -e "\n ============ ipsec statusall ============ \n"
ipsec statusall
echo -e "\n ============ ipsec status ============ \n"
ipsec status
echo -e "\n ============ ipsec-vti.log ============ \n"
cat /var/log/ipsec-vti.log
echo -e "\n ============ link vti ============ \n"
ip link show type vti
echo
EOF
chmod a+x /usr/local/bin/ipsec-debug

%{~ if try(ENABLE_TRAFFIC_GEN, false) ~}
# light-traffic generator

%{ if TARGETS_LIGHT_TRAFFIC_GEN != [] ~}
cat <<EOF > /usr/local/bin/light-traffic
%{ for target in TARGETS_LIGHT_TRAFFIC_GEN ~}
%{~ if try(target.probe, false) ~}
nping -c ${try(target.count, "10")} --${try(target.protocol, "tcp")} -p ${try(target.port, "80")} ${try(target.dns, target.ip)} > /dev/null 2>&1
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/light-traffic
%{ endif ~}

# heavy-traffic generator

%{ if TARGETS_HEAVY_TRAFFIC_GEN != [] ~}
cat <<EOF > /usr/local/bin/heavy-traffic
#! /bin/bash
i=0
while [ \$i -lt 8 ]; do
  %{ for target in TARGETS_HEAVY_TRAFFIC_GEN ~}
  ab -n \$1 -c \$2 ${target} > /dev/null 2>&1
  %{ endfor ~}
  let i=i+1
  sleep 5
done
EOF
chmod a+x /usr/local/bin/heavy-traffic
%{ endif ~}

# crontab for traffic generators

cat <<EOF > /tmp/crontab.txt
%{ if TARGETS_LIGHT_TRAFFIC_GEN != [] ~}
*/1 * * * * /usr/local/bin/light-traffic 2>&1 > /dev/null
%{ endif ~}
%{ if TARGETS_HEAVY_TRAFFIC_GEN != [] ~}
*/1 * * * * /usr/local/bin/heavy-traffic 50 1 2>&1 > /dev/null
*/2 * * * * /usr/local/bin/heavy-traffic 8 2 2>&1 > /dev/null
*/3 * * * * /usr/local/bin/heavy-traffic 20 4 2>&1 > /dev/null
*/5 * * * * /usr/local/bin/heavy-traffic 15 2 2>&1 > /dev/null
%{ endif ~}
EOF
crontab /tmp/crontab.txt
%{ endif ~}
