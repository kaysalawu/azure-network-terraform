#! /bin/bash

apt update
apt install -y python3-pip python3-dev unzip tcpdump dnsutils net-tools nmap apache2-utils iperf3

apt install -y openvpn network-manager-openvpn
sudo service network-manager restart

curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
az login --identity -u /subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/Hs13RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/Hs13-user

# web server #
pip3 install Flask requests

mkdir /var/flaskapp
mkdir /var/flaskapp/flaskapp
mkdir /var/flaskapp/flaskapp/static
mkdir /var/flaskapp/flaskapp/templates

cat <<EOF > /var/flaskapp/flaskapp/__init__.py
import socket
from flask import Flask, request
app = Flask(__name__)

@app.route("/")
def default():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['Hostname'] = hostname
    data_dict['Local-IP'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

@app.route("/path1")
def path1():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH1-APP'
    data_dict['Hostname'] = hostname
    data_dict['Local-IP'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

@app.route("/path2")
def path2():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH2-APP'
    data_dict['Hostname'] = hostname
    data_dict['Local-IP'] = address
    data_dict['Remote-IP'] = request.remote_addr
    data_dict['Headers'] = dict(request.headers)
    return data_dict

if __name__ == "__main__":
    app.run(host= '0.0.0.0', port=80, debug = True)
EOF

cat <<EOF > /etc/systemd/system/flaskapp.service
[Unit]
Description=Script for flaskapp service

[Service]
Type=simple
ExecStart=/usr/bin/python3 /var/flaskapp/flaskapp/__init__.py
ExecStop=/usr/bin/pkill -f /var/flaskapp/flaskapp/__init__.py
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flaskapp.service
systemctl start flaskapp.service

# general scripts
#-----------------------------------

# az login

cat <<EOF > /usr/local/bin/az-login
az login --identity -u /subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/Hs13RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/Hs13-user
EOF
chmod a+x /usr/local/bin/az-login

# test scripts
#-----------------------------------

# ping-ip

cat <<EOF > /usr/local/bin/ping-ip
echo -e "\n ping ip ...\n"
echo "branch1 - 10.10.0.5 -\$(timeout 5 ping -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "hub1    - 10.11.0.5 -\$(timeout 5 ping -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke1  - 10.1.0.5 -\$(timeout 5 ping -qc2 -W1 10.1.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke2  - 10.2.0.5 -\$(timeout 5 ping -qc2 -W1 10.2.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "internet - icanhazip.com -\$(timeout 5 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"
echo "branch1vm.corp - \$(timeout 5 dig +short branch1vm.corp | tail -n1) -\$(timeout 5 ping -qc2 -W1 branch1vm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "hub1vm.eu.az.corp - \$(timeout 5 dig +short hub1vm.eu.az.corp | tail -n1) -\$(timeout 5 ping -qc2 -W1 hub1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke1vm.eu.az.corp - \$(timeout 5 dig +short spoke1vm.eu.az.corp | tail -n1) -\$(timeout 5 ping -qc2 -W1 spoke1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke2vm.eu.az.corp - \$(timeout 5 dig +short spoke2vm.eu.az.corp | tail -n1) -\$(timeout 5 ping -qc2 -W1 spoke2vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "icanhazip.com - \$(timeout 5 dig +short icanhazip.com | tail -n1) -\$(timeout 5 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - branch1 (10.10.0.5)"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    (10.11.0.5)"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.1.0.5) - spoke1  (10.1.0.5)"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.2.0.5) - spoke2  (10.2.0.5)"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - internet (icanhazip.com)"
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1vm.corp) - branch1vm.corp"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1vm.eu.az.corp) - hub1vm.eu.az.corp"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke3pls.eu.az.corp) - spoke3pls.eu.az.corp"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke1vm.eu.az.corp) - spoke1vm.eu.az.corp"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke2vm.eu.az.corp) - spoke2vm.eu.az.corp"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null https://hs13spoke3sae71e.blob.core.windows.net/spoke3/spoke3.txt) - https://hs13spoke3sae71e.blob.core.windows.net/spoke3/spoke3.txt"
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
echo -e "\nbranch1"
echo -e "-------------------------------------"
timeout 9 tracepath 10.10.0.5
echo -e "\nhub1   "
echo -e "-------------------------------------"
timeout 9 tracepath 10.11.0.5
echo -e "\nspoke1 "
echo -e "-------------------------------------"
timeout 9 tracepath 10.1.0.5
echo -e "\nspoke2 "
echo -e "-------------------------------------"
timeout 9 tracepath 10.2.0.5
echo -e "\ninternet"
echo -e "-------------------------------------"
timeout 9 tracepath icanhazip.com
EOF
chmod a+x /usr/local/bin/trace-ip
# light-traffic generator

cat <<EOF > /usr/local/bin/light-traffic
nping -c 10 --tcp -p 80 branch1vm.corp > /dev/null 2>&1
nping -c 10 --tcp -p 80 spoke3pls.eu.az.corp > /dev/null 2>&1
nping -c 10 --tcp -p 80 spoke1vm.eu.az.corp > /dev/null 2>&1
nping -c 10 --tcp -p 80 spoke2vm.eu.az.corp > /dev/null 2>&1
nping -c 10 --tcp -p 80 https://hs13spoke3sae71e.blob.core.windows.net/spoke3/spoke3.txt > /dev/null 2>&1
EOF
chmod a+x /usr/local/bin/light-traffic

# heavy-traffic generator

cat <<EOF > /usr/local/bin/heavy-traffic
#! /bin/bash
i=0
while [ \$i -lt 8 ]; do
    ab -n \$1 -c \$2 branch1vm.corp > /dev/null 2>&1
    ab -n \$1 -c \$2 spoke3pls.eu.az.corp > /dev/null 2>&1
    ab -n \$1 -c \$2 spoke1vm.eu.az.corp > /dev/null 2>&1
    ab -n \$1 -c \$2 spoke2vm.eu.az.corp > /dev/null 2>&1
    ab -n \$1 -c \$2 https://hs13spoke3sae71e.blob.core.windows.net/spoke3/spoke3.txt > /dev/null 2>&1
    let i=i+1
  sleep 5
done
EOF
chmod a+x /usr/local/bin/heavy-traffic

# crontab for traffic generators

cat <<EOF > /tmp/crontab.txt
*/1 * * * * /usr/local/bin/light-traffic 2>&1 > /dev/null
*/1 * * * * /usr/local/bin/heavy-traffic 50 1 2>&1 > /dev/null
*/2 * * * * /usr/local/bin/heavy-traffic 8 2 2>&1 > /dev/null
*/3 * * * * /usr/local/bin/heavy-traffic 20 4 2>&1 > /dev/null
*/5 * * * * /usr/local/bin/heavy-traffic 15 2 2>&1 > /dev/null
EOF
crontab /tmp/crontab.txt
