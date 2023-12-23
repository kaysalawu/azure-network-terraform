#!/bin/sh

# Enable IPv4 and IPv6 forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# Disable ICMP redirects
sysctl -w net.ipv4.conf.all.send_redirects=0
sysctl -w net.ipv4.conf.all.accept_redirects=0
sysctl -w net.ipv6.conf.all.accept_redirects=0
sysctl -w net.ipv4.conf.eth0.send_redirects=0
sysctl -w net.ipv4.conf.eth0.accept_redirects=0
sysctl -w net.ipv6.conf.eth0.accept_redirects=0
echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.accept_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.send_redirects=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.eth0.accept_redirects=0" >> /etc/sysctl.conf
echo "net.ipv6.conf.eth0.accept_redirects=0" >> /etc/sysctl.conf
sysctl -p

apt-get -y update

## Install the Quagga routing daemon
apt-get -y install quagga

##  run the updates and ensure the packages are up to date and there is no new version available for the packages
apt-get -y update --fix-missing
apt-get -y install tcpdump dnsutils traceroute tcptraceroute net-tools

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

## Stopping Quagga (required for script re-runs)
systemctl stop zebra
systemctl stop bgpd

## Create a folder for the quagga logs
echo "creating folder for quagga logs"
sudo mkdir -p /var/log/quagga && sudo chown quagga:quagga /var/log/quagga
sudo touch /var/log/zebra.log
sudo chown quagga:quagga /var/log/zebra.log

## Create the configuration files for Quagga daemon
echo "creating empty quagga config files"
sudo touch /etc/quagga/babeld.conf
sudo touch /etc/quagga/bgpd.conf
sudo touch /etc/quagga/isisd.conf
sudo touch /etc/quagga/ospf6d.conf
sudo touch /etc/quagga/ospfd.conf
sudo touch /etc/quagga/ripd.conf
sudo touch /etc/quagga/ripngd.conf
sudo touch /etc/quagga/vtysh.conf
sudo touch /etc/quagga/zebra.conf

## Change the ownership and permission for configuration files, under /etc/quagga folder
echo "assign to quagga user the ownership of config files"
sudo chown quagga:quagga /etc/quagga/babeld.conf && sudo chmod 640 /etc/quagga/babeld.conf
sudo chown quagga:quagga /etc/quagga/bgpd.conf && sudo chmod 640 /etc/quagga/bgpd.conf
sudo chown quagga:quagga /etc/quagga/isisd.conf && sudo chmod 640 /etc/quagga/isisd.conf
sudo chown quagga:quagga /etc/quagga/ospf6d.conf && sudo chmod 640 /etc/quagga/ospf6d.conf
sudo chown quagga:quagga /etc/quagga/ospfd.conf && sudo chmod 640 /etc/quagga/ospfd.conf
sudo chown quagga:quagga /etc/quagga/ripd.conf && sudo chmod 640 /etc/quagga/ripd.conf
sudo chown quagga:quagga /etc/quagga/ripngd.conf && sudo chmod 640 /etc/quagga/ripngd.conf
sudo chown quagga:quaggavty /etc/quagga/vtysh.conf && sudo chmod 660 /etc/quagga/vtysh.conf
sudo chown quagga:quagga /etc/quagga/zebra.conf && sudo chmod 640 /etc/quagga/zebra.conf

## initial startup configuration for Quagga daemons are required
echo "Setting up daemon startup config"
echo 'zebra=yes' > /etc/quagga/daemons
echo 'bgpd=yes' >> /etc/quagga/daemons
echo 'ospfd=no' >> /etc/quagga/daemons
echo 'ospf6d=no' >> /etc/quagga/daemons
echo 'ripd=no' >> /etc/quagga/daemons
echo 'ripngd=no' >> /etc/quagga/daemons
echo 'isisd=no' >> /etc/quagga/daemons
echo 'babeld=no' >> /etc/quagga/daemons

echo "add zebra config"
cat <<EOF > /etc/quagga/zebra.conf
!
interface eth0
!
interface lo
!
ip forwarding
ipv6 forwarding
!
line vty
!
ip route 0.0.0.0/0 10.22.1.1
ip route 192.168.22.69/32 10.22.1.1
ip route 192.168.22.68/32 10.22.1.1
ip route 10.5.0.0/16 10.22.1.1
!

EOF

echo "add quagga config"
cat <<EOF > /etc/quagga/bgpd.conf
!
log file /var/log/quagga/bgpd.log informational
!
router bgp 65020
  bgp router-id 10.22.1.9
  neighbor 192.168.22.69 remote-as 65515
  neighbor 192.168.22.69 ebgp-multihop 255
  neighbor 192.168.22.69 soft-reconfiguration inbound
  neighbor 192.168.22.68 remote-as 65515
  neighbor 192.168.22.68 ebgp-multihop 255
  neighbor 192.168.22.68 soft-reconfiguration inbound
  network 10.22.0.0/24
  network 10.5.0.0/16
  network 20.107.213.32/32
!
  address-family ipv6
  exit-address-family
  exit
!
line vty
!

EOF

## to start daemons at system startup
systemctl enable zebra.service
systemctl enable bgpd.service

## run the daemons
systemctl restart zebra
systemctl restart bgpd
systemctl start zebra
systemctl start bgpd

# endpoint test scripts
#-----------------------------------

# ping-ip

cat <<EOF > /usr/local/bin/ping-ip
echo -e "\n ping ip ...\n"
echo "branch3 - 10.30.0.5 -\$(ping -qc2 -W1 10.30.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "hub2    - 10.22.0.5 -\$(ping -qc2 -W1 10.22.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke4  - 10.4.0.5 -\$(ping -qc2 -W1 10.4.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke5  - 10.5.0.5 -\$(ping -qc2 -W1 10.5.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"
echo "vm.branch3.corp - \$(dig +short vm.branch3.corp | tail -n1) -\$(ping -qc2 -W1 vm.branch3.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.hub2.az.corp - \$(dig +short vm.hub2.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.hub2.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.spoke4.az.corp - \$(dig +short vm.spoke4.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.spoke4.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.spoke5.az.corp - \$(dig +short vm.spoke5.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.spoke5.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.30.0.5) - branch3 (10.30.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.22.0.5) - hub2    (10.22.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.4.0.5) - spoke4  (10.4.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.5.0.5) - spoke5  (10.5.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.6.0.5) - spoke6  (10.6.0.5)"
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.branch3.corp) - vm.branch3.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.hub2.az.corp) - vm.hub2.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null pep.hub2.az.corp) - pep.hub2.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke4.az.corp) - vm.spoke4.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke5.az.corp) - vm.spoke5.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke6.az.corp) - vm.spoke6.az.corp"
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
traceroute 10.30.0.5
echo -e "branch3\n"
traceroute 10.22.0.5
echo -e "hub2   \n"
traceroute 10.4.0.5
echo -e "spoke4 \n"
traceroute 10.5.0.5
echo -e "spoke5 \n"
EOF
chmod a+x /usr/local/bin/trace-ip
