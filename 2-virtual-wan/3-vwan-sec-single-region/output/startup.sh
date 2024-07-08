#! /bin/bash

apt update
apt install -y python3-pip python3-dev python3-venv unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login --identity || true

########################################################
# test scripts (ipv4)
########################################################

# ping-ipv4

cat <<'EOF' > /usr/local/bin/ping-ipv4
echo -e "\n ping ipv4 ...\n"
echo "branch1 - 10.10.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "hub1    - 10.11.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke1  - 10.1.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.1.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke2  - 10.2.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.2.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "internet - icanhazip.com -$(timeout 3 ping -4 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ipv4

# ping-dns4

cat <<'EOF' > /usr/local/bin/ping-dns4
echo -e "\n ping dns ipv4 ...\n"
echo "branch1vm.corp - $(timeout 3 dig +short branch1vm.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 branch1vm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "hub1vm.eu.az.corp - $(timeout 3 dig +short hub1vm.eu.az.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 hub1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke1vm.eu.az.corp - $(timeout 3 dig +short spoke1vm.eu.az.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 spoke1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke2vm.eu.az.corp - $(timeout 3 dig +short spoke2vm.eu.az.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 spoke2vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "icanhazip.com - $(timeout 3 dig +short icanhazip.com | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ipv4

cat <<'EOF' > /usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [10.10.0.5]) - branch1 [10.10.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [10.11.0.5]) - hub1    [10.11.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [10.1.0.5]) - spoke1  [10.1.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [10.2.0.5]) - spoke2  [10.2.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [icanhazip.com]) - internet [icanhazip.com]"
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4

cat <<'EOF' > /usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1vm.corp) - branch1vm.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1vm.eu.az.corp) - hub1vm.eu.az.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke3pls.eu.az.corp) - spoke3pls.eu.az.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke1vm.eu.az.corp) - spoke1vm.eu.az.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke2vm.eu.az.corp) - spoke2vm.eu.az.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null https://vwan23spoke3sa1afa.blob.core.windows.net/spoke3/spoke3.txt) - https://vwan23spoke3sa1afa.blob.core.windows.net/spoke3/spoke3.txt"
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4

cat <<'EOF' > /usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
echo -e "\nbranch1"
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.10.0.5
echo -e "\nhub1   "
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.11.0.5
echo -e "\nspoke1 "
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.1.0.5
echo -e "\nspoke2 "
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.2.0.5
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
echo "branch1 - fd00:db8:10::5 -$(timeout 3 ping -6 -qc2 -W1 fd00:db8:10::5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "hub1    - fd00:db8:11::5 -$(timeout 3 ping -6 -qc2 -W1 fd00:db8:11::5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke1  - fd00:db8:1::5 -$(timeout 3 ping -6 -qc2 -W1 fd00:db8:1::5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke2  - fd00:db8:2::5 -$(timeout 3 ping -6 -qc2 -W1 fd00:db8:2::5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "internet - icanhazip.com -$(timeout 3 ping -6 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ipv6

# ping-dns6

cat <<'EOF' > /usr/local/bin/ping-dns6
echo -e "\n ping dns ipv6 ...\n"
echo "branch1vm.corp - $(timeout 3 dig AAAA +short branch1vm.corp | tail -n1) -$(timeout 3 ping -6 -qc2 -W1 branch1vm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "hub1vm.eu.az.corp - $(timeout 3 dig AAAA +short hub1vm.eu.az.corp | tail -n1) -$(timeout 3 ping -6 -qc2 -W1 hub1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke1vm.eu.az.corp - $(timeout 3 dig AAAA +short spoke1vm.eu.az.corp | tail -n1) -$(timeout 3 ping -6 -qc2 -W1 spoke1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke2vm.eu.az.corp - $(timeout 3 dig AAAA +short spoke2vm.eu.az.corp | tail -n1) -$(timeout 3 ping -6 -qc2 -W1 spoke2vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "icanhazip.com - $(timeout 3 dig AAAA +short icanhazip.com | tail -n1) -$(timeout 3 ping -6 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-ipv6

cat <<'EOF' > /usr/local/bin/curl-ipv6
echo -e "\n curl ipv6 ...\n"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [fd00:db8:10::5]) - branch1 [fd00:db8:10::5]"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [fd00:db8:11::5]) - hub1    [fd00:db8:11::5]"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [fd00:db8:1::5]) - spoke1  [fd00:db8:1::5]"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [fd00:db8:2::5]) - spoke2  [fd00:db8:2::5]"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [icanhazip.com]) - internet [icanhazip.com]"
EOF
chmod a+x /usr/local/bin/curl-ipv6

# curl-dns6

cat <<'EOF' > /usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1vm.corp) - branch1vm.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1vm.eu.az.corp) - hub1vm.eu.az.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke3pls.eu.az.corp) - spoke3pls.eu.az.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke1vm.eu.az.corp) - spoke1vm.eu.az.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke2vm.eu.az.corp) - spoke2vm.eu.az.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null https://vwan23spoke3sa1afa.blob.core.windows.net/spoke3/spoke3.txt) - https://vwan23spoke3sa1afa.blob.core.windows.net/spoke3/spoke3.txt"
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-ipv6

cat <<'EOF' > /usr/local/bin/trace-ipv6
echo -e "\n trace ipv6 ...\n"
echo -e "\nbranch1"
echo -e "-------------------------------------"
timeout 9 tracepath -6 fd00:db8:10::5
echo -e "\nhub1   "
echo -e "-------------------------------------"
timeout 9 tracepath -6 fd00:db8:11::5
echo -e "\nspoke1 "
echo -e "-------------------------------------"
timeout 9 tracepath -6 fd00:db8:1::5
echo -e "\nspoke2 "
echo -e "-------------------------------------"
timeout 9 tracepath -6 fd00:db8:2::5
echo -e "\ninternet"
echo -e "-------------------------------------"
timeout 9 tracepath -6 icanhazip.com
EOF
chmod a+x /usr/local/bin/trace-ipv6

########################################################
# other scripts
########################################################

# dns-info

cat <<'EOF' > /usr/local/bin/dns-info
echo -e "\n resolvectl ...\n"
resolvectl status
EOF
chmod a+x /usr/local/bin/dns-info

# azure service tester

tee /usr/local/bin/crawlz <<'EOF'
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
