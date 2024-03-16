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
config setup
    charondebug="ike 2, knl 2, cfg 2, net 2, esp 2, dmn 2,  mgr 2"

conn %default
    type=tunnel
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    authby=secret
    keyexchange=ikev2
    installpolicy=yes
    compress=no
    mobike=no
    #left=%defaultroute
    leftsubnet=0.0.0.0/0
    rightsubnet=0.0.0.0/0
    ike=aes256-sha1-modp1024!
    esp=aes256-sha1!

conn Tunnel0
    left=10.10.1.9
    leftid=52.178.208.154
    right=68.219.59.82
    rightid=68.219.59.82
    auto=start
    mark=100
    leftupdown="/etc/ipsec.d/ipsec-vti.sh"
conn Tunnel1
    left=10.10.1.9
    leftid=52.178.208.154
    right=68.219.59.92
    rightid=68.219.59.92
    auto=start
    mark=200
    leftupdown="/etc/ipsec.d/ipsec-vti.sh"

# github source used
# https://gist.github.com/heri16/2f59d22d1d5980796bfb

EOF

tee /etc/ipsec.secrets <<'EOF'
10.10.1.9 68.219.59.82 : PSK "changeme"
10.10.1.9 68.219.59.92 : PSK "changeme"

EOF

tee /etc/ipsec.d/ipsec-vti.sh <<'EOF'
#!/bin/bash

LOG_FILE="/var/log/ipsec-vti.log"

IP=$(which ip)
IPTABLES=$(which iptables)

PLUTO_MARK_OUT_ARR=(${PLUTO_MARK_OUT//// })
PLUTO_MARK_IN_ARR=(${PLUTO_MARK_IN//// })

case "$PLUTO_CONNECTION" in
  Tunnel0)
    VTI_INTERFACE=vti0
    VTI_LOCALADDR=10.10.10.1
    VTI_REMOTEADDR=10.0.0.6
    ;;
  Tunnel1)
    VTI_INTERFACE=vti1
    VTI_LOCALADDR=10.10.10.5
    VTI_REMOTEADDR=10.0.0.7
    ;;
esac

echo "$(date): Trigger - CONN=${PLUTO_CONNECTION}, VERB=${PLUTO_VERB}, ME=${PLUTO_ME}, PEER=${PLUTO_PEER}], PEER_CLIENT=${PLUTO_PEER_CLIENT}, MARK_OUT=${PLUTO_MARK_OUT_ARR}, MARK_IN=${PLUTO_MARK_IN_ARR}" >> $LOG_FILE

case "$PLUTO_VERB" in
  up-client)
    $IP link add ${VTI_INTERFACE} type vti local ${PLUTO_ME} remote ${PLUTO_PEER} okey ${PLUTO_MARK_OUT_ARR[0]} ikey ${PLUTO_MARK_IN_ARR[0]}
    sysctl -w net.ipv4.conf.${VTI_INTERFACE}.disable_policy=1
    sysctl -w net.ipv4.conf.${VTI_INTERFACE}.rp_filter=2 || sysctl -w net.ipv4.conf.${VTI_INTERFACE}.rp_filter=0
    $IP addr add ${VTI_LOCALADDR} remote ${VTI_REMOTEADDR} dev ${VTI_INTERFACE}
    $IP link set ${VTI_INTERFACE} up mtu 1436
    $IPTABLES -t mangle -I FORWARD -o ${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    $IPTABLES -t mangle -I INPUT -p esp -s ${PLUTO_PEER} -d ${PLUTO_ME} -j MARK --set-xmark ${PLUTO_MARK_IN}
    $IP route flush table 220
    #/etc/init.d/bgpd reload || /etc/init.d/quagga force-reload bgpd
    ;;
  down-client)
    $IP link del ${VTI_INTERFACE}
    $IPTABLES -t mangle -D FORWARD -o ${VTI_INTERFACE} -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    $IPTABLES -t mangle -D INPUT -p esp -s ${PLUTO_PEER} -d ${PLUTO_ME} -j MARK --set-xmark ${PLUTO_MARK_IN}
    ;;
esac

# github source used
# https://gist.github.com/heri16/2f59d22d1d5980796bfb

EOF
chmod a+x /etc/ipsec.d/ipsec-vti.sh

# tee /usr/local/bin/ipsec-auto-restart.sh <<'EOF'
# #!/bin/bash

# LOG_FILE="/var/log/ipsec-auto-restart.log"

# connections=$(grep '^conn' /etc/ipsec.conf | grep -v '%default' | cut -d' ' -f2)
# for conn in $connections; do
#   if ! ipsec status | grep -q "$conn"; then
#     echo "$(date): $conn is down. Attempting to restart..." >> "$LOG_FILE"
#     ipsec down $conn
#     ipsec up $conn
#     echo "$(date): $conn restart command issued." >> "$LOG_FILE"
#   fi
# done
# EOF
# chmod a+x /usr/local/bin/ipsec-auto-restart.sh
# /usr/local/bin/ipsec-auto-restart.sh
# echo "*/5 * * * * /usr/local/bin/ipsec-auto-restart.sh" | tee -a /etc/cron.d/ipsec-auto-restart

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
  ip address 192.168.10.10/32
!
!-----------------------------------------
! Static Routes
!-----------------------------------------
ip route 0.0.0.0 10.10.1.1
ip route 10.0.0.6/32 vti0
ip route 10.0.0.7/32 vti1
ip route 10.10.0.0/24 10.10.1.1
!
!-----------------------------------------
! Route Maps
!-----------------------------------------
!
!-----------------------------------------
! BGP
!-----------------------------------------
router bgp 65001
bgp router-id 192.168.10.10
neighbor 10.0.0.6 remote-as 65515
neighbor 10.0.0.6 ebgp-multihop 255
neighbor 10.0.0.6 update-source lo
neighbor 10.0.0.7 remote-as 65515
neighbor 10.0.0.7 ebgp-multihop 255
neighbor 10.0.0.7 update-source lo
!
address-family ipv4 unicast
  network 10.10.0.0/24
  neighbor 10.0.0.6 soft-reconfiguration inbound
  neighbor 10.0.0.7 soft-reconfiguration inbound
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

# ping-ip

cat <<EOF > /usr/local/bin/ping-ip
echo -e "\n ping ip ...\n"
echo "onprem - 10.10.0.5 -\$(ping -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "internet - icanhazip.com -\$(ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"
echo "onpremvm.corp - \$(dig +short onpremvm.corp | tail -n1) -\$(ping -qc2 -W1 onpremvm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "icanhazip.com - \$(dig +short icanhazip.com | tail -n1) -\$(ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - onprem (10.10.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - internet (icanhazip.com)"
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null onpremvm.corp) - onpremvm.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
traceroute 10.10.0.5
echo -e "onprem\n"
traceroute icanhazip.com
echo -e "internet\n"
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
