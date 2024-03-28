#! /bin/bash

# disable systemd-resolved as it conflicts with dnsmasq on port 53

systemctl stop systemd-resolved
systemctl disable systemd-resolved
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "$(hostname -I | cut -d' ' -f1) $(hostname)" >> /etc/hosts

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
        access-control: 127.0.0.0/8 allow
        access-control: 35.199.192.0/19 allow

        # local data records
        local-data: "branch2vm.corp 300 IN A 10.20.0.5"

        # hosts redirected to PrivateLink


forward-zone:
        name: "eu.az.corp."
        forward-addr: 10.11.8.4

forward-zone:
        name: "us.az.corp."
        forward-addr: 10.11.8.4

forward-zone:
        name: "privatelink.blob.core.windows.net."
        forward-addr: 10.11.8.4

forward-zone:
        name: "privatelink.azurewebsites.net."
        forward-addr: 10.11.8.4

forward-zone:
        name: "privatelink.database.windows.net."
        forward-addr: 10.11.8.4

forward-zone:
        name: "privatelink.table.cosmos.azure.com."
        forward-addr: 10.11.8.4

forward-zone:
        name: "privatelink.queue.core.windows.net."
        forward-addr: 10.11.8.4

forward-zone:
        name: "privatelink.file.core.windows.net."
        forward-addr: 10.11.8.4

forward-zone:
        name: "."
        forward-addr: 168.63.129.16
EOF

systemctl enable unbound
systemctl restart unbound
apt install resolvconf
resolvconf -u
