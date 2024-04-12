#! /bin/bash

apt update
apt install -y unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login --identity || true

# test scripts (ip4)
#-----------------------------------

# ping-ip4

cat <<EOF > /usr/local/bin/ping-ip4
echo -e "\n ping ip4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo "${target.name} - ${target.ip} -\$(timeout 3 ping -4 -qc2 -W1 ${target.ip} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-ip4

# ping-dns4

cat <<EOF > /usr/local/bin/ping-dns4
echo -e "\n ping dns ip4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo "${target.dns} - \$(timeout 3 dig +short ${target.dns} | tail -n1) -\$(timeout 3 ping -4 -qc2 -W1 ${target.dns} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns4

# curl-ip4

cat <<EOF > /usr/local/bin/curl-ip4
echo -e "\n curl ip4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo  "\$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.ip}) - ${target.name} (${target.ip})"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-ip4

# curl-dns4

cat <<EOF > /usr/local/bin/curl-dns4
echo -e "\n curl dns ip4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.curl, true) ~}
echo  "\$(timeout 3 curl -4 -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.dns}) - ${target.dns}"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns4

# trace-ip4

cat <<EOF > /usr/local/bin/trace-ip4
echo -e "\n trace ip4 ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo -e "\n${target.name}"
echo -e "-------------------------------------"
timeout 9 tracepath -4 ${target.ip}
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/trace-ip4

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

# traffic generators
#-----------------------------------

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

# crontabs
#-----------------------------------

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