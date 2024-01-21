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
      
      export RESOURCE_GROUP_NAME=G08RG
      export VPN_GATEWAY_NAME=G08-hub1-vpngw
      
      curl $(az network vnet-gateway vpn-client generate \
      --resource-group $RESOURCE_GROUP_NAME \
      --name $VPN_GATEWAY_NAME \
      --authentication-method EAPTLS | tr -d '"') --output ./vpnClient.zip
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
      MIIEIDCCAwigAwIBAgIRAKI1yX6fEMsOGtnkRINCyZowDQYJKoZIhvcNAQELBQAw
      gY4xCzAJBgNVBAYTAlVLMRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25k
      b24xGjAYBgNVBAkTEW1wbHMgY2hpY2tlbiByb2FkMQ0wCwYDVQQKEwRkZW1vMRsw
      GQYDVQQLExJjbG91ZCBuZXR3b3JrIHRlYW0xFDASBgNVBAMTC3Aycy1yb290LWNh
      MB4XDTI0MDEyMTExMTIyOFoXDTI1MDEyMDExMTIyOFowgaUxCzAJBgNVBAYTAlVL
      MRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25kb24xNTAWBgNVBAkTDyBu
      ZXR3b3JrIGF2ZW51ZTAbBgNVBAkTFDk5IG1wbHMgY2hpY2tlbiByb2FkMRMwEQYD
      VQQKEwpuZXR3b3JraW5nMRUwEwYDVQQLEwxuZXR3b3JrIHRlYW0xEDAOBgNVBAMT
      B2NsaWVudDEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDNEaDUB5vE
      VDwcQrdz4Jx9q4U+vzGgVAAKYlIeQ5CnzuDYwOhhiodIKShDL56jrZi6hXrQmOx8
      f22DdepZImnAyOumNEhxjac7U5i6QFO0mAWoHhZ6I/MFhqslLx9QF7nW/xeEbz/z
      fm5N99wFm3e5UAui2w4ic0ltsTEauydT3yWUcQ8EWuzu08al91YzX9WQtQ6q0hNQ
      f5uaFdB1mvpTRUNUrBbpDxWZyn0NNvAo6VMnhQ44AvSvOJh0Oo+OftIgriZ/0cJr
      L0Rh3OlOagF++HnGAxxhty6QAGX7YCBwORyziFHiq3hpkSVJ8cBj7x7zbJB/59do
      ohBDOn2nT+/BAgMBAAGjYDBeMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggr
      BgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBRFEFGl
      4IcdowEy/rEPl9F8sIQT7jANBgkqhkiG9w0BAQsFAAOCAQEAEXWiTzEIfY/5d4VY
      yMbTzYXicFT/TJnigGKeCtDZcVTuUTbQH06O1cKhShtcy42Le0ptK0aSZS/X9QI3
      E/haA3Awc0Fs2pVJhAJuVxZAcnnlq2cCB5SLC/rfkZfFpjgMPv9rpVShWC87lWAT
      eGDozH3hF2nWb2CamioUso13cDTegz8Bju3hhqkDIYsfpMeZ+yuDRYAdZFThbzPf
      axvAtMRQ2qrmVCTdHRpwzqX+EUeR8PBrSwFZsSLqOeUWniFFhHB55k/AVml1PHDL
      aErhNwZAgIidou/PpbcU/5Evo04LyG4gIwACU0o0iyOY/TKM4iip0YaF+eduIfUy
      Ow57MA==
      -----END CERTIFICATE-----
  - path: /var/lib/azure/client1_key.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEogIBAAKCAQEAzRGg1AebxFQ8HEK3c+CcfauFPr8xoFQACmJSHkOQp87g2MDo
      YYqHSCkoQy+eo62YuoV60JjsfH9tg3XqWSJpwMjrpjRIcY2nO1OYukBTtJgFqB4W
      eiPzBYarJS8fUBe51v8XhG8/835uTffcBZt3uVALotsOInNJbbExGrsnU98llHEP
      BFrs7tPGpfdWM1/VkLUOqtITUH+bmhXQdZr6U0VDVKwW6Q8Vmcp9DTbwKOlTJ4UO
      OAL0rziYdDqPjn7SIK4mf9HCay9EYdzpTmoBfvh5xgMcYbcukABl+2AgcDkcs4hR
      4qt4aZElSfHAY+8e82yQf+fXaKIQQzp9p0/vwQIDAQABAoIBAGfQ1tTAjVEVO+Eq
      vWkCevb8EFa1wE/kdqjLIbuEhQUPLLFO59YJpXcYrvNkdjFyvvEehhB4erCEalK1
      LVC2pUcd8H6R1WL3TYQxTA5uZnH0zFhR8xsee/d+N8J5WqbXfBOlzKgVEhEZHoqG
      QnLsQ+4i4eEueLdkGfZYT/2yZbSFSGfqxEW8M4MdON63mEajQEw3LH8v69LEFv2r
      uLGfG0ERNXx/cKCIMODuD2l8QgAL0yLp1fusvGj9HpZcZkPdioIWKI7qlFOvdGet
      B+y7qzFe8yBqHyWJmZcmYGQOI6BcyRl0Gv/Z6Q+yPPHbXDWctKAE6DwvOsKwMxS5
      oVfIPgECgYEAznxhvEPrrgZHQVbOsGStIPMT34rB0dpRX4eeNtExrZHRF0XqA/6z
      QZu0P9BK0luik8EnSevzEAzXYtnDfIyq99h/BMebX+5hwyYf1sd6HQy4nhifEksS
      JAZcqo7Yq/6zsh0eas7EqaiOHvbnIwdy5boK7DHd1mwEYsmFw8VNfjECgYEA/j5C
      nhIseke+ImwHPtAjCupEwcGpy6I5VQMPhke+hgWsuc1R1DNMjhe+LpyuDaB6lvpd
      woa2loUjzx/CJUq6ugRHTv0PlEy39g9EpRIDOqgHT86u5ystxk6wnw6HfPkyAtJP
      olA/sDuP4duoZ84Wgo0Oje+B3yUt1DPPMPm3VpECgYARFT1IxB3FggN3JmVnNo0U
      QsgMIIC0ieldi+zNADWp9Hxl/oTD29icvvMErIjkKmyi6MIFXZ34X/eZ2AZSUZj7
      dE/d5121bBVufcL4k/xIVvsXKVZPvyI7FMOp4LOQVzwqqjoQABdJKgbIDQlGXqFk
      3CV3MRD3Ymxid+W3MqWcoQKBgD93e1nKX6AG2Mfu/8AGZTkMUi2sEp7q2DUIlo+G
      yWDbecrIHm1CgRHXi3pHUovES9X0mgM9bccVZWMHIof8p7BX8RUexwzWOfYKybAL
      VxMFbw3VIoRCmyKt8hlCnz/rVTivF4IFVmC//aL8GoYPRD9CxydXaqwxs8cNR+OJ
      8uKBAoGABPFm05jq27c9Ll7oCjm1/Fbh5cV4jeG1Zl07qvuk3MW+Qed4jyhXhT7P
      6cndNClZvK+6WlwX/aLy/Apn2LBX4szgmUkclEZ3oRprwtUE+3UIQ0pQ7TGGNafc
      Y/iYoJMT1sqPyRPvTzSSawDzuZaXtiDrckG3ofHoixUBS964uy0=
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
      
          apt install -y openvpn network-manager-openvpn
          sudo service network-manager restart
      
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
      echo "branch1 - 192.168.0.5 -\$(timeout 3 ping -qc2 -W1 192.168.0.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
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
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 192.168.0.5) - branch1 (192.168.0.5)"
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
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null g08-spoke3-2ee5.azurewebsites.net) - g08-spoke3-2ee5.azurewebsites.net"
      EOF
      chmod a+x /usr/local/bin/curl-dns
      
      # trace-ip
      
      cat <<EOF > /usr/local/bin/trace-ip
      echo -e "\n trace ip ...\n"
      echo -e "\nbranch1"
      echo -e "-------------------------------------"
      timeout 9 tracepath 192.168.0.5
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
