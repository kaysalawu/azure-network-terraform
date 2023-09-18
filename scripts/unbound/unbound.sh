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
        access-control: 127.0.0.0/8 allow
        access-control: 10.0.0.0/8 allow
        access-control: 192.168.0.0/16 allow
        access-control: 172.16.0.0/12 allow
        access-control: 35.199.192.0/19 allow

        # local data records
        %{~ for tuple in ONPREM_LOCAL_RECORDS ~}
        local-data: "${tuple.name} 3600 IN A ${tuple.record}"
        %{~ endfor ~}

        # hosts redirected to PrivateLink
        %{~ for tuple in REDIRECTED_HOSTS ~}
        %{~ for host in tuple.hosts ~}
        local-zone: ${host} redirect
        %{~ endfor ~}
        %{~ endfor ~}

        %{~ for tuple in REDIRECTED_HOSTS ~}
        %{~ for host in tuple.hosts ~}
        local-data: "${host} ${tuple.ttl} ${tuple.class} ${tuple.type} ${tuple.record}"
        %{~ endfor ~}
        %{~ endfor ~}

%{~ for tuple in FORWARD_ZONES }
forward-zone:
        name: "${tuple.zone}"
        %{~ for target in tuple.targets ~}
        forward-addr: ${target}
        %{~ endfor ~}
%{~ endfor ~}
EOF

sleep 10
systemctl restart unbound
systemctl enable unbound

