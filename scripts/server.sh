#! /bin/bash

apt update
apt install -y python3-pip python3-dev tcpdump dnsutils net-tools

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
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo "${target.name} - ${target.ip} -\$(timeout 3 ping -qc2 -W1 ${target.ip} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-ip

# ping-dns

cat <<EOF > /usr/local/bin/ping-dns
echo -e "\n ping dns ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo "${target.dns} - \$(timeout 3 dig +short ${target.dns} | tail -n1) -\$(timeout 3 ping -qc2 -W1 ${target.dns} 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/ping-dns

# curl-ip

cat <<EOF > /usr/local/bin/curl-ip
echo -e "\n curl ip ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ip, "") != "" ~}
echo  "\$(timeout 3 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.ip}) - ${target.name} (${target.ip})"
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-ip

# curl-dns

cat <<EOF > /usr/local/bin/curl-dns
echo -e "\n curl dns ...\n"
%{ for target in TARGETS ~}
echo  "\$(timeout 3 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%%{http_code} (%%{time_total}s) - %%{remote_ip}" -s -o /dev/null ${target.dns}) - ${target.dns}"
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/curl-dns

# trace-ip

cat <<EOF > /usr/local/bin/trace-ip
echo -e "\n trace ip ...\n"
%{ for target in TARGETS ~}
%{~ if try(target.ping, true) ~}
%{~ if try(target.ip, "") != "" ~}
echo -e "\n${target.name}"
echo -e "-------------------------------------"
timeout 9 tracepath ${target.ip}
%{ endif ~}
%{ endif ~}
%{ endfor ~}
EOF
chmod a+x /usr/local/bin/trace-ip
