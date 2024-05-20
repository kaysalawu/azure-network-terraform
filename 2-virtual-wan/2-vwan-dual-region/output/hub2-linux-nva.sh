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

# Enable IPv6 forwarding
sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf

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

EOF

tee /etc/ipsec.secrets <<'EOF'

EOF

tee /etc/ipsec.d/ipsec-vti.sh <<'EOF'

EOF
chmod a+x /etc/ipsec.d/ipsec-vti.sh

tee /usr/local/bin/ipsec-auto-restart.sh <<'EOF'

EOF
chmod a+x /usr/local/bin/ipsec-auto-restart.sh

touch /var/log/ipsec-vti.log
systemctl enable ipsec
systemctl restart ipsec

#########################################################
# frr  config
#########################################################

tee /etc/frr/frr.conf <<'EOF'
!
!-----------------------------------------
! Global
!-----------------------------------------
frr version 7.2
frr defaults traditional
hostname $(hostname)
log syslog informational
service integrated-vtysh-config
!
!-----------------------------------------
! Prefix Lists
!-----------------------------------------
!
!-----------------------------------------
! Interface
!-----------------------------------------
interface lo
  ip address 10.22.22.22/32
!
!-----------------------------------------
! Static Routes
!-----------------------------------------
ip route 0.0.0.0/0 10.22.2.1
ip route 192.168.22.69/32 10.22.2.1
ip route 192.168.22.68/32 10.22.2.1
ip route 10.5.0.0/16 10.22.2.1
!
!-----------------------------------------
! Route Maps
!-----------------------------------------
!
!-----------------------------------------
! BGP
!-----------------------------------------
router bgp 65020
bgp router-id 10.22.22.22
neighbor 192.168.22.69 remote-as 65515
neighbor 192.168.22.69 ebgp-multihop 255
neighbor 192.168.22.69 update-source lo
neighbor 192.168.22.68 remote-as 65515
neighbor 192.168.22.68 ebgp-multihop 255
neighbor 192.168.22.68 update-source lo
!
address-family ipv4 unicast
  network 10.22.0.0/24
  network 10.5.0.0/16
  neighbor 192.168.22.69 soft-reconfiguration inbound
  neighbor 192.168.22.68 soft-reconfiguration inbound
exit-address-family
!
line vty
!

EOF

systemctl enable frr
systemctl restart frr

#########################################################
# test scripts
#########################################################

# dns-info

cat <<EOF > /usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# azure service tester

tee /usr/local/bin/crawlz <<'EOF'
sudo bash -c "cd /var/lib/azure/crawler/app && ./crawler.sh"
EOF
chmod a+x /usr/local/bin/crawlz

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

# crontabs
#-----------------------------------

cat <<EOF > /etc/cron.d/ipsec-auto-restart
*/10 * * * * /bin/bash /usr/local/bin/ipsec-auto-restart.sh 2>&1 > /dev/null
EOF

crontab /etc/cron.d/ipsec-auto-restart
