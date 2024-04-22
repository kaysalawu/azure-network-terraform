#! /bin/bash

apt update
apt install -y python3-pip python3-dev python3-venv unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login --identity || true

########################################################
# test scripts (ipv4)
########################################################

# ping-ipv4

cat <<EOF > /usr/local/bin/ping-ipv4
echo -e "\n ping ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/ping-ipv4

# ping-dns4

cat <<EOF > /usr/local/bin/ping-dns4
echo -e "\n ping dns ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ipv4

cat <<EOF > /usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4

cat <<EOF > /usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
echo  "\$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null contoso.com) - contoso.com"
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4

cat <<EOF > /usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
EOF
chmod a+x /usr/local/bin/trace-ipv4

########################################################
# test scripts (ipv6)
########################################################

# ping-ipv6

cat <<EOF > /usr/local/bin/ping-ipv6
echo -e "\n ping ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/ping-ipv6

# ping-dns6

cat <<EOF > /usr/local/bin/ping-dns6
echo -e "\n ping dns ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-ipv6

cat <<EOF > /usr/local/bin/curl-ipv6
echo -e "\n curl ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/curl-ipv6

# curl-dns6

cat <<EOF > /usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
echo  "\$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null contoso.com) - contoso.com"
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-ipv6

cat <<EOF > /usr/local/bin/trace-ipv6
echo -e "\n trace ipv6 ...\n"
EOF
chmod a+x /usr/local/bin/trace-ipv6

########################################################
# other scripts
########################################################

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

########################################################
# traffic generators (ipv4)
########################################################

# light-traffic generator


# heavy-traffic generator


########################################################
# crontabs
########################################################

cat <<EOF > /etc/cron.d/traffic-gen
EOF

crontab /etc/cron.d/traffic-gen
