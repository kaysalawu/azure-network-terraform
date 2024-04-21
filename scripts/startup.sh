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
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ipv4, "") != "" ~}
echo "${target.name} - ${target.ipv4} -\$(timeout 3 ping -4 -qc2 -W1 ${target.ipv4} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-ipv4

# ping-dns4

cat <<EOF > /usr/local/bin/ping-dns4
echo -e "\n ping dns ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ipv4, "") != "" ~}
echo "${target.dns} - \$(timeout 3 dig +short ${target.dns} | tail -n1) -\$(timeout 3 ping -4 -qc2 -W1 ${target.dns} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ipv4

cat <<EOF > /usr/local/bin/curl-ipv4
echo -e "\n curl ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
%{~ if try(target.ipv4, "") != "" ~}
echo  "\$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null [${target.ipv4}]) - ${target.name} [${target.ipv4}]"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-ipv4

# curl-dns4

cat <<EOF > /usr/local/bin/curl-dns4
echo -e "\n curl dns ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
echo  "\$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.dns}) - ${target.dns}"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ipv4

cat <<EOF > /usr/local/bin/trace-ipv4
echo -e "\n trace ipv4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ipv4, "") != "" ~}
echo -e "\n${target.name}"
echo -e "-------------------------------------"
timeout 9 tracepath -4 ${target.ipv4}
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/trace-ipv4

########################################################
# test scripts (ipv6)
########################################################

# ping-ipv6

cat <<EOF > /usr/local/bin/ping-ipv6
echo -e "\n ping ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ipv6, "") != "" ~}
echo "${target.name} - ${target.ipv6} -\$(timeout 3 ping -6 -qc2 -W1 ${target.ipv6} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-ipv6

# ping-dns6

cat <<EOF > /usr/local/bin/ping-dns6
echo -e "\n ping dns ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ipv6, "") != "" ~}
echo "${target.dns} - \$(timeout 3 dig AAAA +short ${target.dns} | tail -n1) -\$(timeout 3 ping -6 -qc2 -W1 ${target.dns} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns6

# curl-ipv6

cat <<EOF > /usr/local/bin/curl-ipv6
echo -e "\n curl ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
%{~ if try(target.ipv6, "") != "" ~}
echo  "\$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null [${target.ipv6}]) - ${target.name} [${target.ipv6}]"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-ipv6

# curl-dns6

cat <<EOF > /usr/local/bin/curl-dns6
echo -e "\n curl dns ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
echo  "\$(timeout 3 curl -6 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.dns}) - ${target.dns}"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns6

# trace-ipv6

cat <<EOF > /usr/local/bin/trace-ipv6
echo -e "\n trace ipv6 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ipv6, "") != "" ~}
echo -e "\n${target.name}"
echo -e "-------------------------------------"
timeout 9 tracepath -6 ${target.ipv6}
%{ endif ~}
%{ endif ~}
%{ endfor ~}
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

%{ if TARGETS_LIGHT_TRAFFIC_GEN != [] ~}
cat <<EOF > /usr/local/bin/light-traffic
%{ for target in TARGETS_LIGHT_TRAFFIC_GEN ~}
%{~ if try(target.probe, false) ~}
nping -c ${try(target.count, "10")} --${try(target.protocol, "tcp")} -p ${try(target.port, "80")} ${try(target.dns, target.ip)} > /dev/null 2>&1
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/light-traffic
%{ endif ~}

# heavy-traffic generator

%{ if TARGETS_HEAVY_TRAFFIC_GEN != [] ~}
cat <<EOF > /usr/local/bin/heavy-traffic
#! /bin/bash
i=0
while [ \$i -lt 8 ]; do
  %{ for target in TARGETS_HEAVY_TRAFFIC_GEN ~}
  ab -n \$1 -c \$2 ${target} > /dev/null 2>&1
  %{ endfor ~}
  let i=i+1
  sleep 5
done
EOF
chmod a+x /usr/local/bin/heavy-traffic
%{ endif ~}

########################################################
# crontabs
########################################################

cat <<EOF > /etc/cron.d/traffic-gen
%{ if TARGETS_LIGHT_TRAFFIC_GEN != [] ~}
*/1 * * * * /usr/local/bin/light-traffic 2>&1 > /dev/null
%{ endif ~}
%{ if TARGETS_HEAVY_TRAFFIC_GEN != [] ~}
*/1 * * * * /usr/local/bin/heavy-traffic 50 1 2>&1 > /dev/null
*/2 * * * * /usr/local/bin/heavy-traffic 8 2 2>&1 > /dev/null
*/3 * * * * /usr/local/bin/heavy-traffic 20 4 2>&1 > /dev/null
*/5 * * * * /usr/local/bin/heavy-traffic 15 2 2>&1 > /dev/null
%{ endif ~}
EOF

crontab /etc/cron.d/traffic-gen
