#! /bin/bash

apt update
apt install -y tcpdump bind9-utils dnsutils net-tools
apt install -y unbound

touch /etc/unbound/unbound.log
chmod a+x /etc/unbound/unbound.log

cat <<EOF > /etc/unbound/unbound.conf
server:
        port: 53
        do-ip4: yes
        do-udp: yes
        do-tcp: yes

        interface: 0.0.0.0

        access-control: 0.0.0.0 deny
        access-control: 127.0.0.0/8 allow
        access-control: 10.0.0.0/8 allow
        access-control: 192.168.0.0/16 allow
        access-control: 172.16.0.0/12 allow
        access-control: 35.199.192.0/19 allow

        # local data records
        local-data: "vm.branch1.corp 3600 IN A 10.10.0.5"
        local-data: "vm.branch2.corp 3600 IN A 10.20.0.5"
        local-data: "vm.branch3.corp 3600 IN A 10.30.0.5"
        local-data: "vm.branch4.corp 3600 IN A 10.40.0.5"

        # hosts redirected to PrivateLink


forward-zone:
        name: "az.corp."
        forward-addr: 10.11.5.4
        forward-addr: 10.22.5.4

forward-zone:
        name: "."
        forward-addr: 168.63.129.16
EOF

sleep 10
systemctl restart unbound
systemctl enable unbound

