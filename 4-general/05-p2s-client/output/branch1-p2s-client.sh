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
      MIIEIDCCAwigAwIBAgIRAPS/whlNZ03JwPE6zsAOvM0wDQYJKoZIhvcNAQELBQAw
      gY4xCzAJBgNVBAYTAlVLMRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25k
      b24xGjAYBgNVBAkTEW1wbHMgY2hpY2tlbiByb2FkMQ0wCwYDVQQKEwRkZW1vMRsw
      GQYDVQQLExJjbG91ZCBuZXR3b3JrIHRlYW0xFDASBgNVBAMTC3Aycy1yb290LWNh
      MB4XDTI0MDQwMzEwNDQxMloXDTI1MDQwMzEwNDQxMlowgaUxCzAJBgNVBAYTAlVL
      MRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25kb24xNTAWBgNVBAkTDyBu
      ZXR3b3JrIGF2ZW51ZTAbBgNVBAkTFDk5IG1wbHMgY2hpY2tlbiByb2FkMRMwEQYD
      VQQKEwpuZXR3b3JraW5nMRUwEwYDVQQLEwxuZXR3b3JrIHRlYW0xEDAOBgNVBAMT
      B2NsaWVudDEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDAPISt+Ek+
      yBIIGQdwuKN1xqFWxNEGADAxKYMe2bnInecGlAKW46Sn5Iq2JEIEvVIqyZEqSBHu
      UV9NbeWdbbL3u53y6l3XrfFCU2yWsiEVNuLHoli+DTOr+ABzFl2GJE8NAJDSxj0J
      ce9R4TDUePr0TZn7HnvYhPVO1SNy8VxOKQyfwTB+bORwJc2xKFbvLtn/P2nlVgme
      NaaWBYMIyk/yihsjPDK7WZxqtfY+LmN0fm3igtq/kqVLYs7DfxeMzm3q54UDw/2d
      ym0iAiSY9iV1wWuMFX46YB4oK/ouf0YLEx9uaA/+CKcB/ItQKNELfVD0Yx2Wq1ri
      Xity9lefgMn1AgMBAAGjYDBeMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggr
      BgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBT5rzvA
      GzNGxwCabyVKNwGKANWtlDANBgkqhkiG9w0BAQsFAAOCAQEAfkhkQDbirDNGOm04
      QDx6ssfnEVIZwU4hmDuI6eAjlpwqQamOapN11xWdCtGkPFmbVM7jPHr4vJtrYt3O
      3gOO2PZrmNGSdjC83pEjJ+JagiWSSt95o86SmV7bC325NpW/uAMTsT8a5PrmDCno
      5ctJCI6DVH/YA9JrM96RL7W1jGupWzMANcCRBG3oCA6AyE86Z1YUU5BWXhZKMegu
      03J98w8NnlkUxSjDKKM5XHS/NvBAXVKpx1bdI2rpRPGzdtJ3X+87ZSu7L9lrtlnl
      jzlMslGzpKXPVWXnFDuhKV70fb9Ydx7fh4PBc3WoiB7XexAQEiugQTJKyX0/Ywac
      ilsKTA==
      -----END CERTIFICATE-----
  - path: /var/lib/azure/client1_key.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpQIBAAKCAQEAwDyErfhJPsgSCBkHcLijdcahVsTRBgAwMSmDHtm5yJ3nBpQC
      luOkp+SKtiRCBL1SKsmRKkgR7lFfTW3lnW2y97ud8upd163xQlNslrIhFTbix6JY
      vg0zq/gAcxZdhiRPDQCQ0sY9CXHvUeEw1Hj69E2Z+x572IT1TtUjcvFcTikMn8Ew
      fmzkcCXNsShW7y7Z/z9p5VYJnjWmlgWDCMpP8oobIzwyu1mcarX2Pi5jdH5t4oLa
      v5KlS2LOw38XjM5t6ueFA8P9ncptIgIkmPYldcFrjBV+OmAeKCv6Ln9GCxMfbmgP
      /ginAfyLUCjRC31Q9GMdlqta4l4rcvZXn4DJ9QIDAQABAoIBABcEaAKIkwSQYhBU
      Jt7pTLEialkAUeK9DQgl50w/V45c0beo6zJz6Vgs9ire5oS4wmjbH6WHYZY+agHU
      YcTayK3+6eeXBkt3yUZexMa6Z1mp67dpieSfogs6M5uUFvijyk9NPQnvsIk7+iK8
      quMV5T5xODmoKb4AFXst7AOsQJge/tP1ND5BrU2vZ5FsV8RNnLNsuRfwsLzhGkp3
      +wL2sqlE3Kx9vkpt4HomNzfqZOJva/I6/3kgyQ6bFEdpox8kzZMNq5zk7wVXf6j1
      gMZjojsWKNk4eS8Eu4M9DnC774m3S3EFeJbHmCDQLxdBfe29VPmcDJf/eSdjgz8J
      jzgfNxUCgYEAzBqfU+JgxHOzRps1nA8FqTkkyatkcl6v0vr56/Kp33kmEUQsGJZF
      nkhoGSvydBMvfMfkuPcMBI4rQYRVLkrOh4c4vK3JrNCAWaMvMWic5+jW62oDumXt
      FW61M5bTPSgBBHIb55Lj1MtOon5nvk0A2Ztma96PpdPAQrbMR0EgYCMCgYEA8R1r
      dG0jAjil5vDCgW+5+bQU7rKoyOIX0ClXjj9GZKpXnFddyW13Exw/AfbwxqvHYH5R
      ebNgjLpXdjK8moLCtOdP9KdCQRF02Jgih0W8j2FiCWb17G49xkU9LB/+wpgCLgcQ
      9Unk4ZlKkpzRtJV4K02ZvTvfxarMaP6Pc2SHQwcCgYEAxVyI7IheohhvJrs236z3
      AGetVwVQn/dHdXAS80E3Wky/rrqJGU1WDHRflNeWHv/eT37LgMAC8vS2hyf7ZkQX
      6Z2sE2bJOT50njjZjaFm+CmCiSl+aWPeGXdv6G7T3LMuKKpeqVK01DOz2hT5JF85
      jzJhm7Uemm9j3h788XncYJkCgYEAhG6AQqZfAC1VEg9TBfzzzO7YQHLouc1U/wR2
      Dq86Xrgg/sINxUDWkiyFfvK/NJ/NFnbLEWkwspr2xvj/Fm6TuwEBrYLgpRSNdRm6
      fUoUUzxNuJRQpte2HlyRSNcZ+o+7QsSmz9MSX8buarCvjdw68K3ir0lfkxZIx7Jp
      4BtrH6kCgYEAnjqdP31xBTc26+ZpW0+EFEuwWlG5bAsfWjjiF/yY3tCJcos4oU8c
      Po6GGbrU9EfTfGIlo8UjgGqKD6VQNPK/Gt3kwNWOak4Sef2xLMZNEkljP5ME9jp+
      MAv5HaZpz8bC5F4yQUDknotG3XU8rTv4EOYoPwQ/HjB6zphjXpgLcRY=
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
      apt install -y python3-pip python3-dev python3-venv unzip jq tcpdump dnsutils net-tools nmap apache2-utils iperf3
      
      pip3 install azure-identity
      pip3 install azure-mgmt-network
      
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
      echo "branch1 - 10.10.0.5 -\$(timeout 3 ping -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "hub1    - 10.11.0.5 -\$(timeout 3 ping -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "internet - icanhazip.com -\$(timeout 3 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      EOF
      chmod a+x /usr/local/bin/ping-ip
      
      # ping-dns
      
      cat <<EOF > /usr/local/bin/ping-dns
      echo -e "\n ping dns ...\n"
      echo "branch1vm.corp - \$(timeout 3 dig +short branch1vm.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 branch1vm.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "hub1vm.eu.az.corp - \$(timeout 3 dig +short hub1vm.eu.az.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 hub1vm.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "icanhazip.com - \$(timeout 3 dig +short icanhazip.com | tail -n1) -\$(timeout 3 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      EOF
      chmod a+x /usr/local/bin/ping-dns
      
      # curl-ip
      
      cat <<EOF > /usr/local/bin/curl-ip
      echo -e "\n curl ip ...\n"
      echo  "\$(timeout 3 curl -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - branch1 (10.10.0.5)"
      echo  "\$(timeout 3 curl -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    (10.11.0.5)"
      echo  "\$(timeout 3 curl -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - internet (icanhazip.com)"
      EOF
      chmod a+x /usr/local/bin/curl-ip
      
      # curl-dns
      
      cat <<EOF > /usr/local/bin/curl-dns
      echo -e "\n curl dns ...\n"
      echo  "\$(timeout 3 curl -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null branch1vm.corp) - branch1vm.corp"
      echo  "\$(timeout 3 curl -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null hub1vm.eu.az.corp) - hub1vm.eu.az.corp"
      echo  "\$(timeout 3 curl -kL --max-time 3.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
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
      
      # azure service tester
      
      tee /usr/local/bin/crawlz <<'EOF'
      sudo bash -c "cd /var/lib/azure/crawler/app && ./crawler.sh"
      EOF
      chmod a+x /usr/local/bin/crawlz
      
      # light-traffic generator
      
      
      # heavy-traffic generator
      
      
      # crontabs
      #-----------------------------------
      
      cat <<EOF > /etc/cron.d/traffic-gen
      EOF
      
      crontab /etc/cron.d/traffic-gen
      
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
  - echo 'RESOURCE_GROUP_NAME=Lab05_P2sClient_RG' >> /var/lib/azure/.env
  - echo 'VPN_GATEWAY_NAME=Lab05-hub1-vpngw' >> /var/lib/azure/.env
