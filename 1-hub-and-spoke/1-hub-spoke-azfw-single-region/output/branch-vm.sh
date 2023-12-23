#! /bin/bash

apt update
apt install -y wget python3-pip python3-dev \
tcpdump fping dnsutils traceroute tcptraceroute nmap hping3 iperf3 net-tools \
speedtest-cli

# web server
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
    data_dict['hostname'] = hostname
    data_dict['local-ip'] = address
    data_dict['remote-ip'] = request.remote_addr
    data_dict['headers'] = dict(request.headers)
    return data_dict

@app.route("/path1")
def path1():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH1-APP'
    data_dict['hostname'] = hostname
    data_dict['local-ip'] = address
    data_dict['remote-ip'] = request.remote_addr
    data_dict['headers'] = dict(request.headers)
    return data_dict

@app.route("/path2")
def path2():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'PATH2-APP'
    data_dict['hostname'] = hostname
    data_dict['local-ip'] = address
    data_dict['remote-ip'] = request.remote_addr
    data_dict['headers'] = dict(request.headers)
    return data_dict

if __name__ == "__main__":
    app.run(host= '0.0.0.0', port=80, debug = True)
EOF
nohup python3 /var/flaskapp/flaskapp/__init__.py &

cat <<EOF > /var/tmp/startup.sh
nohup python3 /var/flaskapp/flaskapp/__init__.py &
EOF

echo "@reboot source /var/tmp/startup.sh" >> /var/tmp/crontab_flask.txt
crontab /var/tmp/crontab_flask.txt

# test scripts
#-----------------------------------

# ping-ip

cat <<EOF > /usr/local/bin/ping-ip
echo -e "\n ping ip ...\n"
echo "branch1 - 10.10.0.5 -\$(ping -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "branch1-2 - 10.1.0.5 -\$(ping -qc2 -W1 10.1.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "hub1    - 10.11.0.5 -\$(ping -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke1  - 10.1.0.5 -\$(ping -qc2 -W1 10.1.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke2  - 10.2.0.5 -\$(ping -qc2 -W1 10.2.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "branch3 - 10.30.0.5 -\$(ping -qc2 -W1 10.30.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "hub2    - 10.22.0.5 -\$(ping -qc2 -W1 10.22.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke4  - 10.4.0.5 -\$(ping -qc2 -W1 10.4.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "spoke5  - 10.5.0.5 -\$(ping -qc2 -W1 10.5.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"
echo "vm.branch1.corp - \$(dig +short vm.branch1.corp | tail -n1) -\$(ping -qc2 -W1 vm.branch1.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm2.branch1.corp - \$(dig +short vm2.branch1.corp | tail -n1) -\$(ping -qc2 -W1 vm2.branch1.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.hub1.az.corp - \$(dig +short vm.hub1.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.hub1.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.spoke1.az.corp - \$(dig +short vm.spoke1.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.spoke1.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.spoke2.az.corp - \$(dig +short vm.spoke2.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.spoke2.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.branch3.corp - \$(dig +short vm.branch3.corp | tail -n1) -\$(ping -qc2 -W1 vm.branch3.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.hub2.az.corp - \$(dig +short vm.hub2.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.hub2.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.spoke4.az.corp - \$(dig +short vm.spoke4.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.spoke4.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
echo "vm.spoke5.az.corp - \$(dig +short vm.spoke5.az.corp | tail -n1) -\$(ping -qc2 -W1 vm.spoke5.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - branch1 (10.10.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.1.0.5) - branch1-2 (10.1.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    (10.11.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.1.0.5) - spoke1  (10.1.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.2.0.5) - spoke2  (10.2.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.3.0.5) - spoke3  (10.3.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.30.0.5) - branch3 (10.30.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.22.0.5) - hub2    (10.22.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.4.0.5) - spoke4  (10.4.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.5.0.5) - spoke5  (10.5.0.5)"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.6.0.5) - spoke6  (10.6.0.5)"
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.branch1.corp) - vm.branch1.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm2.branch1.corp) - vm2.branch1.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.hub1.az.corp) - vm.hub1.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null pep.hub1.az.corp) - pep.hub1.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke1.az.corp) - vm.spoke1.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke2.az.corp) - vm.spoke2.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke3.az.corp) - vm.spoke3.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.branch3.corp) - vm.branch3.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.hub2.az.corp) - vm.hub2.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null pep.hub2.az.corp) - pep.hub2.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke4.az.corp) - vm.spoke4.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke5.az.corp) - vm.spoke5.az.corp"
echo  "\$(curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke6.az.corp) - vm.spoke6.az.corp"
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
traceroute 10.10.0.5
echo -e "branch1\n"
traceroute 10.1.0.5
echo -e "branch1-2\n"
traceroute 10.11.0.5
echo -e "hub1   \n"
traceroute 10.1.0.5
echo -e "spoke1 \n"
traceroute 10.2.0.5
echo -e "spoke2 \n"
traceroute 10.30.0.5
echo -e "branch3\n"
traceroute 10.22.0.5
echo -e "hub2   \n"
traceroute 10.4.0.5
echo -e "spoke4 \n"
traceroute 10.5.0.5
echo -e "spoke5 \n"
EOF
chmod a+x /usr/local/bin/trace-ip
