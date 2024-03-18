#cloud-config

package_update: true
package_upgrade: true
packages:
  - docker.io
  - docker-compose

write_files:
  - path: /var/lib/azure/client-config.sh
    owner: root
    permissions: 0744
    content: |
      #!/bin/bash

      if [ "$1" == "-h" ] || [ "$1" == "--helper" ]; then
          echo "Usage: $0 RESOURCE_GROUP_NAME VPN_GATEWAY_NAME"
          return 0
      fi

      if [ $# -eq 2 ]; then
          RESOURCE_GROUP_NAME=$1
          VPN_GATEWAY_NAME=$2
      else
          source .env
      fi

      echo -e "\nchecking vnet gateway...\n"
      curl $(az network vnet-gateway vpn-client generate \
      --resource-group $RESOURCE_GROUP_NAME \
      --name $VPN_GATEWAY_NAME \
      --authentication-method EAPTLS | tr -d '"') --output ./vpnClient.zip

      if [ $? -ne 0 ]; then
          echo -e "\nchecking vwan p2s gateway...\n"
          curl $(az network p2s-vpn-gateway vpn-client generate \
          --resource-group $RESOURCE_GROUP_NAME \
          --name $VPN_GATEWAY_NAME \
          --authentication-method EAPTLS 2>/dev/null | jq -r '.profileUrl') --output ./vpnClient.zip
      fi

      if [ $? -ne 0 ]; then
          return 1
      fi

      unzip vpnClient.zip -d vpnClient
      rm vpnClient.zip

      VPN_CLIENT_CERT=$(awk '{printf "%s\\n", $0}' ./*_cert.pem)
      VPN_CLIENT_KEY=$(awk '{printf "%s\\n", $0}' ./*_key.pem)

      sed -i "s~\$CLIENTCERTIFICATE~$VPN_CLIENT_CERT~" "./vpnClient/OpenVPN/vpnconfig.ovpn"
      sed -i "s~\$PRIVATEKEY~$VPN_CLIENT_KEY~g" "./vpnClient/OpenVPN/vpnconfig.ovpn"

      echo "sudo openvpn --config ./vpnClient/OpenVPN/vpnconfig.ovpn"
      sudo openvpn --config ./vpnClient/OpenVPN/vpnconfig.ovpn &
      sleep 3
      echo "ps aux | grep "[o]penvpn""
      ps aux | grep "[o]penvpn"

  - path: /var/lib/azure/client1_cert.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN CERTIFICATE-----
      MIIEIDCCAwigAwIBAgIRAM35czpAf2K6sFhDo/V5fIEwDQYJKoZIhvcNAQELBQAw
      gY4xCzAJBgNVBAYTAlVLMRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25k
      b24xGjAYBgNVBAkTEW1wbHMgY2hpY2tlbiByb2FkMQ0wCwYDVQQKEwRkZW1vMRsw
      GQYDVQQLExJjbG91ZCBuZXR3b3JrIHRlYW0xFDASBgNVBAMTC3Aycy1yb290LWNh
      MB4XDTI0MDMxMjEzMzkxNloXDTI1MDMxMjEzMzkxNlowgaUxCzAJBgNVBAYTAlVL
      MRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25kb24xNTAWBgNVBAkTDyBu
      ZXR3b3JrIGF2ZW51ZTAbBgNVBAkTFDk5IG1wbHMgY2hpY2tlbiByb2FkMRMwEQYD
      VQQKEwpuZXR3b3JraW5nMRUwEwYDVQQLEwxuZXR3b3JrIHRlYW0xEDAOBgNVBAMT
      B2NsaWVudDEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDEKEfonp7o
      SKtDDIv5k18ovO3fKkyTrehOmtkpuATKI6TKtjTfGtzoP+CmnXF22Ht9Fp8pVcMi
      lRe18i4+8f1Lp4nKjuZ5k3wt0qY9Ewwa37G8092OjRP4uZN9KandhZShKaOXsWBk
      vgyF6G9GHEN7J3i7u37RvFHj3/ipnyzzaoqOcmmtqNa8WmaR2vDDcRro6hulldBj
      zNWYLUQmoJXWEiF3j7NOIJDilxXyR4hOqa5TFI4+ms3FGZIhRqdc0W3DpFDV2RaV
      LUEGXwqHzNzUMARKZDkJn6P046rjg4ple6hWOyKX+m2AYWAw0M1Z6Bq4EAa8zMkm
      AXWjQi4WHaujAgMBAAGjYDBeMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggr
      BgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBSg7vTq
      tnXX3EM8spSTNpL44YoqwTANBgkqhkiG9w0BAQsFAAOCAQEAZfqWrRXz4xwqS+Cb
      1zypHF/BospmeuOkHJJO4ymPrLh81EQWv8vQ71XVQcNGYkV2Zxeaux1VcrKQjtn8
      2/sxahEj3nudDuji5rkb10RrsSUkzzlFzmquMw6HZ6eTJOn9YI5p1fK8Dyb7asQ1
      z7gsmlMyfHUd/WRr3UKrdKdD7E+Pl5DyvrEmfgSoPzJPJaDne32Scgw1VLIZU/zr
      GxxFeYSy5jY3X4N5qOU5GO8VhcBBuQsbSpU53LkLk2dB8gSmPE2QfzkXqHbrFat6
      Sw/+bXvFvK0VYpuMCv7msvbDZShrVqGrZhglB5nPEvyk2sdpsMTArTjrtg0nisvX
      PdAWlQ==
      -----END CERTIFICATE-----
  - path: /var/lib/azure/client1_key.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEAxChH6J6e6EirQwyL+ZNfKLzt3ypMk63oTprZKbgEyiOkyrY0
      3xrc6D/gpp1xdth7fRafKVXDIpUXtfIuPvH9S6eJyo7meZN8LdKmPRMMGt+xvNPd
      jo0T+LmTfSmp3YWUoSmjl7FgZL4MhehvRhxDeyd4u7t+0bxR49/4qZ8s82qKjnJp
      rajWvFpmkdrww3Ea6OobpZXQY8zVmC1EJqCV1hIhd4+zTiCQ4pcV8keITqmuUxSO
      PprNxRmSIUanXNFtw6RQ1dkWlS1BBl8Kh8zc1DAESmQ5CZ+j9OOq44OKZXuoVjsi
      l/ptgGFgMNDNWegauBAGvMzJJgF1o0IuFh2rowIDAQABAoIBAQDDBR1BC/sHC8Ch
      v6amsjtIoFWKq15I8PzmsZM4pAi3A6sCExcLvYRlr6RlYmD9fIuBuOzyxp5kEoDp
      Vuddk292ORKIfXxs4RHz6Nt4GyjMyxvFlYpQALkbbz1Qkgyc/gLgHCrWVPZ2EnEW
      7Rk8RjtdBMhHNUkHsshj2zg5Q9UIB2YwBhRMfF7XuaVXHtjaOou0/RtHctrlDHux
      Wv2iP7tE2y6e37UEwApowt75sm8FYTlOapCwRbjm/C/qgfF1R+qTue2PHX7FsHOP
      /TPx05YYz/dLwpYZC7lokwEWiTeXZ+0PMOLUeR2IBRzxsMZnuxjl+RMcZyBkhIiM
      FYyq51ChAoGBAOJHLqnPEYVWoKMG+9nEU34hcqthwreJMJYQt4RnMcz4uYlDPQzD
      Bru2z3DViPFabeVpUUrb3Bhtwvg8raJrzb3A/O8mzlxs6EXJs+5CbRwtj9A9ByBS
      5ILg9yM6KJgHAjM/ZUydYiPcX796VcOTBiXtOnTGquNrMVaoDhBGUuyRAoGBAN3s
      QsESzvRwAX6sJSnD03AHrrHNS3u9Gi87fpndG1nTXl9H/nH81ifRVXZU61h+8+jR
      W0JOTwrZOMzfYG4ynnBBoBqfzBqOzY4txUoYL1IGcwEHGO/yvyiWvstJ71/8Ilmq
      He+zUNDTAZCn572cneFhBfJ/kyOVvlCN+lB8XD7zAoGASgPYqqjV5VShtNHq/Z9v
      ZBmSxaZzp89TOjL7pG6Q5qgRIGoDBTKh+DLjBdiDM9dNjTX25lKmWsNEfCh072Tt
      5nzC/4MlCyyAiZthpLTLteTdXtMnipYysvDdRgOXFattN9Ar1XTBjlNeamacuR1V
      bIB9l4cIjN0aRWsxNneaVlECgYB3d0g4R7fBPsqPNnyLDzAzju8sKCgKZLJD2vM8
      QRsIMBENmeQP2NwwczBekzheW3lSS+GkwCMs4+L/5wAyUm2YYLufmYZ2hYmCkIE0
      cfCHZ5FhbECway0c3Im5RgPm2ARl4H5dG1rWD8E37iuCl10mhuR8ttCux128X7Hw
      wgGmoQKBgQC8vWpm+USi8NejcHDAMkKKt3O6YWWoSnZo7rZgHHtxRYX4N6WAKpiS
      4dqhSJZOPwLML6UFd0fW+Q113xNTHgFV9jC4caOmc6C8mK/JEln32a+j0XiJ4bhn
      c+XYMzeMYXHXqzX2vnAKqe62bQbptdYDPuQuC8lTQTa0PQXX+fatjQ==
      -----END RSA PRIVATE KEY-----
  - path: /var/lib/azure/docker-compose.yml
    owner: root
    permissions: 0744
    content: |
      version: '3'
      services:
        web:
          container_name: web
          build:
            context: ./web
            dockerfile: Dockerfile
          network_mode: host

  - path: /var/lib/azure/server.sh
    owner: root
    permissions: 0744
    content: |
      #! /bin/bash

      apt update
      apt install -y python3-pip python3-dev unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3

      apt install -y openvpn network-manager-openvpn
      sudo service network-manager restart

      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
      az login --identity || true

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

      # test scripts
      #-----------------------------------

      # ping-ip

      cat <<EOF > /usr/local/bin/ping-ip
      echo -e "\n ping ip ...\n"
      echo "branch1 - 10.10.0.5 -\$(timeout 5 ping -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "hub1    - 10.11.0.5 -\$(timeout 5 ping -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "internet - icanhazip.com -\$(timeout 5 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      EOF
      chmod a+x /usr/local/bin/ping-ip

      # ping-dns

      cat <<EOF > /usr/local/bin/ping-dns
      echo -e "\n ping dns ...\n"
      echo "branch1vm.corp - \$(timeout 5 dig +short branch1vm.corp | tail -n1) -\$(timeout 5 ping -qc2 -W1 branch1vm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "hub1vm.eu.az.corp - \$(timeout 5 dig +short hub1vm.eu.az.corp | tail -n1) -\$(timeout 5 ping -qc2 -W1 hub1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "icanhazip.com - \$(timeout 5 dig +short icanhazip.com | tail -n1) -\$(timeout 5 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      EOF
      chmod a+x /usr/local/bin/ping-dns

      # curl-ip

      cat <<EOF > /usr/local/bin/curl-ip
      echo -e "\n curl ip ...\n"
      echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - branch1 (10.10.0.5)"
      echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    (10.11.0.5)"
      echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - internet (icanhazip.com)"
      EOF
      chmod a+x /usr/local/bin/curl-ip

      # curl-dns

      cat <<EOF > /usr/local/bin/curl-dns
      echo -e "\n curl dns ...\n"
      echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1vm.corp) - branch1vm.corp"
      echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1vm.eu.az.corp) - hub1vm.eu.az.corp"
      echo  "\$(timeout 5 curl -kL --max-time 5.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
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
      echo -e "\ninternet"
      echo -e "-------------------------------------"
      timeout 9 tracepath icanhazip.com
      EOF
      chmod a+x /usr/local/bin/trace-ip

      # dns-info

      cat <<EOF > /usr/local/bin/dns-info
      echo -e "\n resolvectl ...\n"
      resolvectl status
      EOF
      chmod a+x /usr/local/bin/dns-info

  - path: /var/lib/azure/service.sh
    owner: root
    permissions: 0744
    content: |
      #! /bin/bash

      set -e

      base_dir=$(pwd)
      init_dir="/var/lib/azure"
      log_init="$init_dir/log_init.txt"

      echo "HOST_HOSTNAME: $HOST_HOSTNAME" | tee -a "$log_init"
      echo "HOST_IP: $HOST_IP" | tee -a "$log_init"

      if [ ! -d "$init_dir" ]; then mkdir -p "$init_dir"; fi

      echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
      echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf
      sysctl -p

      # ubuntu 22 fix
      sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf || true

      cat <<EOF > /etc/motd
      ################################################
                          Client
      ################################################
      Docker Ubuntu
       Date:     $(date)
      - Version:  1.0
      - Distro:   $(cat /etc/issue)
      - Packages:
        - Docker
      ################################################

      EOF

      display_delimiter() {
        echo "####################################################################################"
        date
        echo $(basename "$0")
      }

      install_packages() {
          echo "*****************************************"
          echo " Step 1: Install packages"
          echo "*****************************************"
          apt-get update
          apt-get install -y unzip tcpdump dnsutils net-tools nmap apache2-utils

          apt install -y openvpn network-manager-openvpn
          sudo service network-manager restart

          curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
          az login --identity

          echo "*****************************************"
          echo " Step 2: Cleanup apt"
          echo "*****************************************"
          apt-get --purge -y autoremove
          apt-get clean
          echo "done!"
      }

      start_services() {
        echo "**************************************"
        echo "STEP 3: Start Services"
        echo "**************************************"
        cd "$init_dir"
        export HOST_HOSTNAME=$(hostname)
        export HOST_IP=$(hostname -I | awk '{print $1}')
        HOST_HOSTNAME=$(hostname) HOST_IP=$(hostname -I | awk '{print $1}') docker-compose up -d
        cd "$dir_base"
      }

      check_services() {
        echo "**************************************"
        echo "STEP : Check Service Status"
        echo "**************************************"
        echo "sleep 3 ..." && sleep 3
        echo "docker ps"
        docker ps
      }

      systemd_config() {
        echo "**********************************************************"
        echo "STEP 5:  Systemd Service for webapp"
        echo "**********************************************************"
        echo "Create: /etc/systemd/system/webapp.service"
        cat <<EOF > /etc/systemd/system/webapp.service
        [Unit]
        Description=Script for webapp

        [Service]
        Type=oneshot
        ExecStart=-$init_dir/start.sh
        RemainAfterExit=true
        ExecStop=-$init_dir/stop.sh
        StandardOutput=journal

        [Install]
        WantedBy=multi-user.target
      EOF
        cat /etc/systemd/system/webapp.service
        systemctl start webapp
        systemctl enable webapp
      }

      start=$(date +%s)
      display_delimiter | tee -a "$log_init"
      install_packages | tee -a "$log_init"
      start_services | tee -a "$log_init"
      check_services | tee -a "$log_init"
      systemd_config | tee -a "$log_init"
      end=$(date +%s)
      elapsed=$(($end-$start))
      echo "Completed in $(($elapsed/60))m $(($elapsed%60))s!" | tee -a "$log_init"

  - path: /var/lib/azure/start.sh
    owner: root
    permissions: 0744
    content: |
      #!/bin/bash

      set -e

      base_dir=$(pwd)
      init_dir="/var/lib/azure"
      log_service="$init_dir/log_service.txt"

      display_delimiter() {
        echo "####################################################################################"
        date
        echo $(basename "$0")
        echo "SYSTEMCTL - Start"
      }

      start_services() {
        echo "**************************************"
        echo "STEP 1: Start Services"
        echo "**************************************"
        cd "$init_dir"
        export HOST_HOSTNAME=$(hostname)
        export HOST_IP=$(hostname -I | awk '{print $1}')
        HOST_HOSTNAME=$(hostname) HOST_IP=$(hostname -I | awk '{print $1}') docker compose up -d
        cd "$dir_base"
      }

      check_services() {
        echo "**************************************"
        echo "STEP 2: Check Service Status"
        echo "**************************************"
        echo "sleep 3 ..." && sleep 3
        echo "docker ps"
        docker ps
      }

      start=$(date +%s)
      display_delimiter | tee -a $log_service
      start_services | tee -a $log_service
      check_services | tee -a $log_service
      end=$(date +%s)
      elapsed=$(($end-$start))
      echo "Completed in $(($elapsed/60))m $(($elapsed%60))s!" | tee -a $log_service

  - path: /var/lib/azure/stop.sh
    owner: root
    permissions: 0744
    content: |
      #!/bin/bash

      set -e

      base_dir=$(pwd)
      init_dir="/var/lib/azure"
      log_service="$init_dir/log_service.txt"

      display_delimiter() {
        echo "####################################################################################"
        date
        echo $(basename "$0")
        echo "SYSTEMCTL - Start"
      }

      stop_services() {
        echo "**************************************"
        echo " Stop Services"
        echo "**************************************"
        cd "$init_dir"
        echo "docker compose down"
        docker compose down
        docker rm -vf $(docker ps -aq) || true
        docker rmi -f $(docker images -aq) || true
        cd "$dir_base"
      }

      check_services() {
        echo "**************************************"
        echo " Check Service Status"
        echo "**************************************"
        echo "sleep 3 ..." && sleep 3
        docker ps
        echo ""
        echo "#####################"
        echo "netstat -tupanl|egrep \"80|8080|8081\"|grep -i listen"
        netstat -tupanl|egrep "80|8080|8081"|grep -i listen
      }

      start=$(date +%s)
      display_delimiter | tee -a $log_service
      stop_services | tee -a $log_service
      check_services | tee -a $log_service
      end=$(date +%s)
      elapsed=$(($end-$start))
      echo "Completed in $(($elapsed/60))m $(($elapsed%60))s!" | tee -a $log_service

  - path: /var/lib/azure/web/.dockerignore
    owner: root
    permissions: 0744
    content: |
      Dockerfile
      docker-compose*
      .gitignore
      pyvenv.cfg
      tests
      node_modules/
      npm-debug.log
      bin/
      include/
      lib/
      lib64/

  - path: /var/lib/azure/web/Dockerfile
    owner: root
    permissions: 0744
    content: |
      FROM python:3.12-alpine

      WORKDIR /app
      COPY . .
      RUN pip install --verbose --no-cache-dir -r requirements.txt
      EXPOSE 80
      CMD ["python3", "main.py"]

  - path: /var/lib/azure/web/_app.py
    owner: root
    permissions: 0744
    content: |
      import os
      import socket
      from fastapi import APIRouter, Request, HTTPException

      router = APIRouter()

      hostname = socket.gethostname()
      address = socket.gethostbyname(hostname)

      @router.get("/")
      async def default(request: Request):
          data_dict = {
              'app': 'Web-Home',
              'hostname': os.getenv('HOST_HOSTNAME', hostname),
              'local-ip': os.getenv('HOST_IP', address),
              'remote-ip': request.client.host,
              'headers': dict(request.headers)
          }
          return data_dict

      @router.get("/path1")
      async def path1(request: Request):
          data_dict = {
              'app': 'Web-Path1',
              'hostname': os.getenv('HOST_HOSTNAME', hostname),
              'local-ip': os.getenv('HOST_IP', address),
              'remote-ip': request.client.host,
              'headers': dict(request.headers)
          }
          return data_dict

      @router.get("/path2")
      async def path2(request: Request):
          data_dict = {
              'app': 'Web-Path2',
              'hostname': os.getenv('HOST_HOSTNAME', hostname),
              'local-ip': os.getenv('HOST_IP', address),
              'remote-ip': request.client.host,
              'headers': dict(request.headers)
          }
          return data_dict

      @router.get("/healthz")
      async def healthz(request: Request):
          # allowed_hosts = ["healthz.az.corp"]
          # if request.client.host not in allowed_hosts:
          #     raise HTTPException(status_code=403, detail="Access denied")
          return "OK"

  - path: /var/lib/azure/web/main.py
    owner: root
    permissions: 0744
    content: |
      from fastapi import FastAPI, Request, Response, HTTPException
      from fastapi.middleware.cors import CORSMiddleware
      from fastapi.responses import JSONResponse
      from _app import router as app_router
      import json
      import ssl
      import uvicorn

      class PrettyJSONResponse(Response):
          media_type = "application/json"

          def render(self, content: any) -> bytes:
              return json.dumps(content, indent=2).encode('utf-8')

      app = FastAPI(default_response_class=PrettyJSONResponse)

      # CORS middleware
      app.add_middleware(
          CORSMiddleware,
          allow_origins=["*"],  # Replace * with actual frontend domain
          allow_credentials=True,
          allow_methods=["*"],
          allow_headers=["*"],
      )

      # Custom middleware to add Access-Control-Allow-Origin header
      @app.middleware("http")
      async def add_cors_header(request, call_next):
          response = await call_next(request)
          response.headers["Access-Control-Allow-Origin"] = "*"
          return response

      # Include the API router
      app.include_router(app_router, tags=["Features"])

      if __name__ == "__main__":
          uvicorn.run(
              "main:app",
              host="0.0.0.0",
              port=80
          )


  - path: /var/lib/azure/web/requirements.txt
    owner: root
    permissions: 0744
    content: |
      cryptography==41.0.7
      fastapi==0.105.0
      uvicorn==0.25.0


runcmd:
  - bash /var/lib/azure/server.sh
  - bash /var/lib/azure/service.sh
  - echo 'RESOURCE_GROUP_NAME=G08RG' >> /var/lib/azure/.env
  - echo 'VPN_GATEWAY_NAME=G08-hub1-vpngw' >> /var/lib/azure/.env
