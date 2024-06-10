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
echo "cgs1 - 192.168.2.4 -$(timeout 3 ping -4 -qc2 -W1 192.168.2.4 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "cgs2 - 192.168.2.5 -$(timeout 3 ping -4 -qc2 -W1 192.168.2.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "prod - 192.168.0.5 -$(timeout 3 ping -4 -qc2 -W1 192.168.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "prodha - 192.168.0.6 -$(timeout 3 ping -4 -qc2 -W1 192.168.0.6 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "nonprod - 192.168.1.5 -$(timeout 3 ping -4 -qc2 -W1 192.168.1.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "naf - 192.168.3.5 -$(timeout 3 ping -4 -qc2 -W1 192.168.3.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke4  - 10.4.0.5 -$(timeout 3 ping -4 -qc2 -W1 10.4.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "internet - icanhazip.com -$(timeout 3 ping -4 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ipv4

# ping-dns4

cat <<'EOF' > /usr/local/bin/ping-dns4
echo -e "\n ping dns ipv4 ...\n"
echo "branch1vm.corp - $(timeout 3 dig +short branch1vm.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 branch1vm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "cgs1.ecs.corp - $(timeout 3 dig +short cgs1.ecs.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 cgs1.ecs.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "cgs2.ecs.corp - $(timeout 3 dig +short cgs2.ecs.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 cgs2.ecs.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "prodvm.ecs.corp - $(timeout 3 dig +short prodvm.ecs.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 prodvm.ecs.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "prodhavm.ecs.corp - $(timeout 3 dig +short prodhavm.ecs.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 prodhavm.ecs.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "nonprodvm.ecs.corp - $(timeout 3 dig +short nonprodvm.ecs.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 nonprodvm.ecs.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "nafvm.ecs.corp - $(timeout 3 dig +short nafvm.ecs.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 nafvm.ecs.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "spoke4vm.us.az.corp - $(timeout 3 dig +short spoke4vm.us.az.corp | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 spoke4vm.us.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
echo "icanhazip.com - $(timeout 3 dig +short icanhazip.com | tail -n1) -$(timeout 3 ping -4 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ipv4

cat <<'EOF' > /usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [10.10.0.5]) - branch1 [10.10.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [192.168.2.4]) - cgs1 [192.168.2.4]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [192.168.2.5]) - cgs2 [192.168.2.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [192.168.0.5]) - prod [192.168.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [192.168.0.6]) - prodha [192.168.0.6]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [192.168.1.5]) - nonprod [192.168.1.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [192.168.3.5]) - naf [192.168.3.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [10.4.0.5]) - spoke4  [10.4.0.5]"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [icanhazip.com]) - internet [icanhazip.com]"
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4

cat <<'EOF' > /usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1vm.corp) - branch1vm.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null cgs1.ecs.corp) - cgs1.ecs.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null cgs2.ecs.corp) - cgs2.ecs.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null prodvm.ecs.corp) - prodvm.ecs.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null prodhavm.ecs.corp) - prodhavm.ecs.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nonprodvm.ecs.corp) - nonprodvm.ecs.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nafvm.ecs.corp) - nafvm.ecs.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke4vm.us.az.corp) - spoke4vm.us.az.corp"
echo  "$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4

cat <<'EOF' > /usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
echo -e "\nbranch1"
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.10.0.5
echo -e "\ncgs1"
echo -e "-------------------------------------"
timeout 9 tracepath -4 192.168.2.4
echo -e "\ncgs2"
echo -e "-------------------------------------"
timeout 9 tracepath -4 192.168.2.5
echo -e "\nprod"
echo -e "-------------------------------------"
timeout 9 tracepath -4 192.168.0.5
echo -e "\nprodha"
echo -e "-------------------------------------"
timeout 9 tracepath -4 192.168.0.6
echo -e "\nnonprod"
echo -e "-------------------------------------"
timeout 9 tracepath -4 192.168.1.5
echo -e "\nnaf"
echo -e "-------------------------------------"
timeout 9 tracepath -4 192.168.3.5
echo -e "\nspoke4 "
echo -e "-------------------------------------"
timeout 9 tracepath -4 10.4.0.5
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
echo "internet - icanhazip.com -$(timeout 3 ping -6 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ipv6

# ping-dns6

cat <<'EOF' > /usr/local/bin/ping-dns6
echo -e "\n ping dns ipv6 ...\n"
echo "icanhazip.com - $(timeout 3 dig AAAA +short icanhazip.com | tail -n1) -$(timeout 3 ping -6 -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-ipv6

cat <<'EOF' > /usr/local/bin/curl-ipv6
echo -e "\n curl ipv6 ...\n"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null [icanhazip.com]) - internet [icanhazip.com]"
EOF
chmod a+x /usr/local/bin/curl-ipv6

# curl-dns6

cat <<'EOF' > /usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1vm.corp) - branch1vm.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null cgs1.ecs.corp) - cgs1.ecs.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null cgs2.ecs.corp) - cgs2.ecs.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null prodvm.ecs.corp) - prodvm.ecs.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null prodhavm.ecs.corp) - prodhavm.ecs.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nonprodvm.ecs.corp) - nonprodvm.ecs.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null nafvm.ecs.corp) - nafvm.ecs.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke4vm.us.az.corp) - spoke4vm.us.az.corp"
echo  "$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-ipv6

cat <<'EOF' > /usr/local/bin/trace-ipv6
echo -e "\n trace ipv6 ...\n"
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

cat <<'EOF' > /usr/local/bin/light-traffic
EOF
chmod a+x /usr/local/bin/light-traffic

# heavy-traffic generator


########################################################
# traffic generators (ipv6)
########################################################

# light-traffic generator

cat <<'EOF' > /usr/local/bin/light-traffic-ipv6
EOF
chmod a+x /usr/local/bin/light-traffic-ipv6

# heavy-traffic generator


########################################################
# crontabs
########################################################

cat <<'EOF' > /etc/cron.d/traffic-gen
*/1 * * * * /usr/local/bin/light-traffic 2>&1 > /dev/null
EOF

crontab /etc/cron.d/traffic-gen
