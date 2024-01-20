#cloud-config

package_update: true
package_upgrade: true
packages:
  - docker.io
  - docker-compose

write_files:
  - path: /var/lib/azure/client-config-gen.sh
    owner: root
    permissions: 0744
    content: |
      #!/bin/bash
      
      if [ $# -ne 2 ] || [ "$1" == "-h" ] || [ "$1" == "--helper" ]; then
          echo -e "\nUsage: $0 RESOURCE_GROUP_NAME VPN_GATEWAY_NAME\n"
          return 1
      fi
      
      curl $(az network vnet-gateway vpn-client generate \
      --resource-group $1 \
      --name $2 \
      --authentication-method EAPTLS | tr -d '"') --output ./vpnClient.zip
      unzip vpnClient.zip -d vpnClient
      
      VPN_CLIENT_CERT=$(awk '{printf "%s\\n", $0}' ./*_cert.pem)
      VPN_CLIENT_KEY=$(awk '{printf "%s\\n", $0}' ./*_key.pem)
      
      sed -i "s~\$CLIENTCERTIFICATE~$VPN_CLIENT_CERT~" "./vpnClient/OpenVPN/vpnconfig.ovpn"
      sed -i "s~\$PRIVATEKEY~$VPN_CLIENT_KEY~g" "./vpnClient/OpenVPN/vpnconfig.ovpn"
      
  - path: /var/lib/azure/client1_cert.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN CERTIFICATE-----
      MIIEIDCCAwigAwIBAgIRALRG4SMG53GzqABzniL4ymMwDQYJKoZIhvcNAQELBQAw
      gY4xCzAJBgNVBAYTAlVLMRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25k
      b24xGjAYBgNVBAkTEW1wbHMgY2hpY2tlbiByb2FkMQ0wCwYDVQQKEwRkZW1vMRsw
      GQYDVQQLExJjbG91ZCBuZXR3b3JrIHRlYW0xFDASBgNVBAMTC3Aycy1yb290LWNh
      MB4XDTI0MDEyMDE0NDM1MFoXDTI1MDExOTE0NDM1MFowgaUxCzAJBgNVBAYTAlVL
      MRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25kb24xNTAWBgNVBAkTDyBu
      ZXR3b3JrIGF2ZW51ZTAbBgNVBAkTFDk5IG1wbHMgY2hpY2tlbiByb2FkMRMwEQYD
      VQQKEwpuZXR3b3JraW5nMRUwEwYDVQQLEwxuZXR3b3JrIHRlYW0xEDAOBgNVBAMT
      B2NsaWVudDEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDONjD18ZGO
      0RXljHuIHo7UCtzaGS4mXL/Knr/cl7A/bAnMzfovbi4UUuJ4O5FRflTJ5squoS06
      G/SkzFYyUXYK97if4V8loglPfzI+Nc+cN9+SkMXNyDRL1YXZwKoUlv+rrvb6+TvS
      G33nbaW+dRiKiBwsTulOlzT+k0nHDdjm71izAH6KLPf300FZHkLKouzRiCuZ//Us
      tHyYtbUUga/z4yvIrFfX4z7tapesrzEvFY1bW8ctSweyoGfh3XUtj8+9kMii1j8H
      Ge60v0S6ujBOzUnmU49va6YM7DJHHpoxFUmKd/DFF3MeJdL/UrATHAI79Uau5lna
      Gu6pgDhCx7mxAgMBAAGjYDBeMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggr
      BgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBSM7HyL
      1eCd4kXSEBumCuaLGKaMbDANBgkqhkiG9w0BAQsFAAOCAQEAdy9rRMwTq5FdytYu
      /KA7heE3f+Abfv6HFyhAl7mfnKkSKcLTYEf1w+OPyjKKaJYWXJm1uC4+yrJRw9/H
      H5E1dafGgxWzbYivuqHxhwhjvpfX3FApVS93hjAAs6PmxBPljPLlIIlL8g97qqzg
      1ZlgOD9Dm9yB3Hl36eRg7Q2r8Gb5c6ZRFMoKJJXDW+ulrh8k9d8SBH7xO8bEkEtl
      oRFfwWVbwp6n4DQgtXVV9Q6ilTEu1ZDaNUeG3vOJbRiARBhCGyizluog9fU0dToO
      Zy1dS/39ffv2y250EMstSTD/wvI+IvH5oa1ETxQeNLIRfB7vM/tf+5tK6CaweGOO
      JzlgZQ==
      -----END CERTIFICATE-----
  - path: /var/lib/azure/client1_key.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEogIBAAKCAQEAzjYw9fGRjtEV5Yx7iB6O1Arc2hkuJly/yp6/3JewP2wJzM36
      L24uFFLieDuRUX5UyebKrqEtOhv0pMxWMlF2Cve4n+FfJaIJT38yPjXPnDffkpDF
      zcg0S9WF2cCqFJb/q672+vk70ht9522lvnUYiogcLE7pTpc0/pNJxw3Y5u9YswB+
      iiz399NBWR5CyqLs0Ygrmf/1LLR8mLW1FIGv8+MryKxX1+M+7WqXrK8xLxWNW1vH
      LUsHsqBn4d11LY/PvZDIotY/BxnutL9EurowTs1J5lOPb2umDOwyRx6aMRVJinfw
      xRdzHiXS/1KwExwCO/VGruZZ2hruqYA4Qse5sQIDAQABAoIBAEQkwk8z8e7pBzxh
      DR1xQ6+sm0jzUz3YHoT9qtdhxRtgP2jPlGKCHXYX4cDrplzwy2IhA09r8b8nJ9Qh
      tkZQhxqevAMRfdi40CzWEqteKuoryJTthIA5LZb1y5KmyU2ejISWgAV1wR/wd823
      fTMQDPkSe4Tk2tJew2NxFstRtyCw1XpRirSp7E6sCR/xvUBfk8Jz1II/xUgCX3wY
      0ncjtw+L5d0yNBgvENzghRijidmEtm6zPQPVzbfv9aT9OVv+fDD/UWylVhh8lYxC
      WiMyLFMbPmdwpHRmzaTjWKezBiMfx2Bk4pYy4ovWgnhOGTb6Z+kSTPed55pJcth3
      M33SeAECgYEA3HnJj51Uh0cvmFo9M1sw05YV5YdCDxdyqWWQh4EkJMncOL1b4yYT
      J6Zn4r3xQvMJEqjabMj8i85kQQeTUExsv+QB0ROBlRy59fS054Q4JQZQSwIHCT4H
      y39IjM0TxYnGWugIcmVWYUVvVfPEaVPn2sOatdaFZ9aceAYgVhLtToECgYEA73AJ
      32b4FZ3aKuenNSphLn9KPNQZz1e6kTMSF8RZG8ZnMz23fjqxthau5guo2T2LF0fZ
      88miqgTRBq1uiSbJPxFSgt3kxb5StV/PR582MlLQE7k5UR4ejHU0wBin27VvXLTZ
      WQ4jhujoD4dn6YQ2GBX3yrtiVm2JWUPN0PC4MzECgYBSN1wxoPLfi201PBlsaEoZ
      7PL3Z+v7YrwQbV5rGX5X9aqYwgxc9VrZQ1WkGT65v5WXjr39KSn8HJgIJAIMRKOd
      HzKKO+Lrrw2tqXY4i3bAX81bW0MycB5KBYoRb3w7ArikN7jGqAGBPnpZLBEHUhG4
      445y1q9i3IX2wBoY3u/9gQKBgG94mrAOMStnLP3SkW7YBxxtmHNPT6DPOAWHYEH+
      YHnk2YDql7XFv5yFXPGutfJFi67P/bFYy0kaKvJP5ekmTIT3HJHemjZRkBHuxAKV
      Jdcx5Lt5/Sw9uH0tx9wy3lsUUf84FwQ15+ZUIk2wfXki20hFWfJhYLvaDRqozXYb
      y7XRAoGAU9sgzmxSJV/9kAola0qv/8W13oTmHmt1u1mpEXItSzjPSEdK3LXuaz4A
      Crj7XlP4cMjoe6eYUSzWByOs1loiQ2Y2Ix5MqROIq45iCKpEgANlezhfmTiJTEnh
      XOgbLcuW3PFXJAJRPqCKEOMjWw65GPKYVimVjIfhsh54FIbLK0o=
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
          curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
          az login --identity -u /subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/G08RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/G08-user
      
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
      
  - path: /var/lib/azure/tools.sh
    owner: root
    permissions: 0744
    content: |
      #! /bin/bash
      
      # general scripts
      #-----------------------------------
      
      # az login
      
      cat <<EOF > /usr/local/bin/az-login
      az login --identity -u /subscriptions/b120edff-2b3e-4896-adb7-55d2918f337f/resourceGroups/G08RG/providers/Microsoft.ManagedIdentity/userAssignedIdentities/G08-user
      EOF
      chmod a+x /usr/local/bin/az-login
      
      # test scripts
      #-----------------------------------
      
      # ping-ip
      
      cat <<EOF > /usr/local/bin/ping-ip
      echo -e "\n ping ip ...\n"
      echo "branch1 - 10.10.0.5 -\$(timeout 3 ping -qc2 -W1 10.10.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "hub1    - 10.11.0.5 -\$(timeout 3 ping -qc2 -W1 10.11.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "spoke1  - 10.1.0.5 -\$(timeout 3 ping -qc2 -W1 10.1.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "spoke2  - 10.2.0.5 -\$(timeout 3 ping -qc2 -W1 10.2.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "internet - icanhazip.com -\$(timeout 3 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      EOF
      chmod a+x /usr/local/bin/ping-ip
      
      # ping-dns
      
      cat <<EOF > /usr/local/bin/ping-dns
      echo -e "\n ping dns ...\n"
      echo "vm.branch1.corp - \$(timeout 3 dig +short vm.branch1.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 vm.branch1.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "vm.hub1.we.az.corp - \$(timeout 3 dig +short vm.hub1.we.az.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 vm.hub1.we.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "vm.spoke1.we.az.corp - \$(timeout 3 dig +short vm.spoke1.we.az.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 vm.spoke1.we.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "vm.spoke2.we.az.corp - \$(timeout 3 dig +short vm.spoke2.we.az.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 vm.spoke2.we.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "icanhazip.com - \$(timeout 3 dig +short icanhazip.com | tail -n1) -\$(timeout 3 ping -qc2 -W1 icanhazip.com 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      EOF
      chmod a+x /usr/local/bin/ping-dns
      
      # curl-ip
      
      cat <<EOF > /usr/local/bin/curl-ip
      echo -e "\n curl ip ...\n"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.0.5) - branch1 (10.10.0.5)"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.11.0.5) - hub1    (10.11.0.5)"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.1.0.5) - spoke1  (10.1.0.5)"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.2.0.5) - spoke2  (10.2.0.5)"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.3.0.5) - spoke3  (10.3.0.5)"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - internet (icanhazip.com)"
      EOF
      chmod a+x /usr/local/bin/curl-ip
      
      # curl-dns
      
      cat <<EOF > /usr/local/bin/curl-dns
      echo -e "\n curl dns ...\n"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.branch1.corp) - vm.branch1.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.hub1.we.az.corp) - vm.hub1.we.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke3.p.hub1.we.az.corp) - spoke3.p.hub1.we.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke1.we.az.corp) - vm.spoke1.we.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke2.we.az.corp) - vm.spoke2.we.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke3.we.az.corp) - vm.spoke3.we.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null g08-spoke3-5694.azurewebsites.net) - g08-spoke3-5694.azurewebsites.net"
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
  - . /var/lib/azure/service.sh
  - . /var/lib/azure/tools.sh
