#! /bin/bash

apt update
apt install -y tcpdump dnsutils net-tools
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
        access-control: 10.0.0.0/8 allow
        access-control: 172.16.0.0/12 allow
        access-control: 192.168.0.0/16 allow
        access-control: 100.64.0.0/10 allow
        access-control: 53.200.0.0/16 allow
        access-control: 127.0.0.0/8 allow
        access-control: 35.199.192.0/19 allow
        access-control: 53.200.0.0/16 allow

        # local data records
        local-data: "vm.branch1.co.net 300 IN A 10.10.0.5"
        local-data: "vm.branch2.co.net 300 IN A 10.20.0.5"
        local-data: "vm.branch3.co.net 300 IN A 10.30.0.5"

        # hosts redirected to PrivateLink


forward-zone:
        name: "cloud.co.net."
        forward-addr: 53.200.117.4
        forward-addr: 53.200.229.4

forward-zone:
        name: "."
        forward-addr: 168.63.129.16
EOF

systemctl stop systemd-resolved
systemctl disable systemd-resolved
systemctl restart unbound
systemctl enable unbound

