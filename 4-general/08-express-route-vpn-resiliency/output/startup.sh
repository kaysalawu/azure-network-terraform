#! /bin/bash

exec > /var/log/azure-startup.log

apt update
apt install -y python3-pip python3-dev python3-venv unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

########################################################
# test scripts (ipv4)
########################################################

# ping-ipv4

cat <<'EOF' > /usr/local/bin/ping-ipv4
echo -e "\n ping ipv4 ...\n"
echo "branch2 - 10.20.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.20.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "hub1    - 10.11.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke1  - 10.1.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.1.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "internet - icanhazip.com -$(timeout 3 ping -4 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ipv4

# ping-dns4

cat <<'EOF' > /usr/local/bin/ping-dns4
echo -e "\n ping dns ipv4 ...\n"
echo "branch2vm.corp - $(timeout 3 dig +short branch2vm.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 branch2vm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "hub1vm.eu.az.corp - $(timeout 3 dig +short hub1vm.eu.az.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 hub1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke1vm.eu.az.corp - $(timeout 3 dig +short spoke1vm.eu.az.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 spoke1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "icanhazip.com - $(timeout 3 dig +short icanhazip.com | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ipv4

cat <<'EOF' > /usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.20.0.5) - branch2 [10.20.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    [10.11.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.1.0.5) - spoke1  [10.1.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - internet [icanhazip.com]"
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4

cat <<'EOF' > /usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch2vm.corp) - branch2vm.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1vm.eu.az.corp) - hub1vm.eu.az.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke1vm.eu.az.corp) - spoke1vm.eu.az.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4

cat <<'EOF' > /usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
echo -e "\nbranch2"
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.20.0.5
echo -e "\nhub1   "
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.11.0.5
echo -e "\nspoke1 "
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.1.0.5
echo -e "\ninternet"
echo -e "-------------------------------------"
timeout 9 tracepath -4 icanhazip.com
EOF
chmod a+x /usr/local/bin/trace-ipv4

########################################################
# test scripts (ipv6)
########################################################

# ping-ipv6

cat <<'EOF' > /usr/local/bin/ping-ipv6
echo -e "\n ping ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/ping-ipv6

# ping-dns6

cat <<'EOF' > /usr/local/bin/ping-dns6
echo -e "\n ping dns ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-ipv6

cat <<'EOF' > /usr/local/bin/curl-ipv6
echo -e "\n curl ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/curl-ipv6

# curl-dns6

cat <<'EOF' > /usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch2vm.corp) - branch2vm.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1vm.eu.az.corp) - hub1vm.eu.az.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke1vm.eu.az.corp) - spoke1vm.eu.az.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-ipv6

cat <<'EOF' > /usr/local/bin/trace-ipv6
echo -e "\n trace ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/trace-ipv6

#########################################################
# other scripts
#########################################################

# dns-info

cat <<'EOF' > /usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# azure service tester

cat <<'EOF' > /usr/local/bin/crawlz
sudo bash -c "cd /var/lib/azure/crawler/app && ./crawler.sh"
EOF
chmod a+x /usr/local/bin/crawlz

########################################################
# traffic generators (ipv4)
########################################################

# light-traffic generator


# heavy-traffic generator


########################################################
# traffic generators (ipv6)
########################################################

# light-traffic generator


# heavy-traffic generator


########################################################
# crontabs
########################################################

cat <<'EOF' > /etc/cron.d/traffic-gen
EOF

crontab /etc/cron.d/traffic-gen
