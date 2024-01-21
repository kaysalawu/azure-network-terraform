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
      MIIEHzCCAwegAwIBAgIQW92i9ImVmnXvQv6yPH0kSjANBgkqhkiG9w0BAQsFADCB
      jjELMAkGA1UEBhMCVUsxEDAOBgNVBAgTB0VuZ2xhbmQxDzANBgNVBAcTBkxvbmRv
      bjEaMBgGA1UECRMRbXBscyBjaGlja2VuIHJvYWQxDTALBgNVBAoTBGRlbW8xGzAZ
      BgNVBAsTEmNsb3VkIG5ldHdvcmsgdGVhbTEUMBIGA1UEAxMLcDJzLXJvb3QtY2Ew
      HhcNMjQwMTIxMDExNjE1WhcNMjUwMTIwMDExNjE1WjCBpTELMAkGA1UEBhMCVUsx
      EDAOBgNVBAgTB0VuZ2xhbmQxDzANBgNVBAcTBkxvbmRvbjE1MBYGA1UECRMPIG5l
      dHdvcmsgYXZlbnVlMBsGA1UECRMUOTkgbXBscyBjaGlja2VuIHJvYWQxEzARBgNV
      BAoTCm5ldHdvcmtpbmcxFTATBgNVBAsTDG5ldHdvcmsgdGVhbTEQMA4GA1UEAxMH
      Y2xpZW50MTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMeGYaSBUl0k
      16Z7zkY8uxBUsMpVZwcpXs0xa4SG/Gp3X9TsN1CL1U+EsOuGkRYLN0C/DTnQasfz
      EiIulSdPicrnTODq3J38irrz2ndFddpNJIA9MzX7QLkkAYoZCvadtEIFl3I9PIwN
      BcYRJzEs0tYnRUw1wP/pX8WNUuwJxzzSq7fEFvX1UeMRNYaZYo0L4tqHIQblvN1r
      U2qRcB4OYh1a27ZxbBs5mXWheCeBNexTagHM730lowjxjlc7WdxkDb+g6Q7hueZG
      fMAqdznMI1YflcGOL3JBq7cayNyzpdTReKoJILzRYTD8EHIYNKNwyn3nMaopC098
      7us2S/OpXPkCAwEAAaNgMF4wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsG
      AQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFCczIKzt
      b/Z5jBesaUODZ9pdFBP2MA0GCSqGSIb3DQEBCwUAA4IBAQCcZK0I0alXMHZeh4iu
      OZsR43MuhAWZpgn/O1yr0eeoiR5TaFkh5ZtDARvTqj0//oT7QviQB0kL5G6tGRNB
      34V3W4U9/5y5bgttrQz6rfQmHb/JDIOC8o+Fjj1Qw6CVjoYYi6gip4OPsgDJwE6D
      r8tzBQ8lTe8EqLZNuUZU8fZppaqEPO9QV1KBH6dGwU6KJ21ERUZn1vDXUeaSmvE3
      xRHMttj0gIH6XHMh080uDFan8yqo/ooo36/NNuShDmr2igQXFPC+M/iP2HCDI9V/
      bLjMhra3Unt5xWysfJcQdkrXcz3JOf7yfn9g7rS9t74uB4uhWqiIKBvvI1f8SfJ1
      p/22
      -----END CERTIFICATE-----
  - path: /var/lib/azure/client1_key.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpAIBAAKCAQEAx4ZhpIFSXSTXpnvORjy7EFSwylVnBylezTFrhIb8andf1Ow3
      UIvVT4Sw64aRFgs3QL8NOdBqx/MSIi6VJ0+JyudM4OrcnfyKuvPad0V12k0kgD0z
      NftAuSQBihkK9p20QgWXcj08jA0FxhEnMSzS1idFTDXA/+lfxY1S7AnHPNKrt8QW
      9fVR4xE1hplijQvi2ochBuW83WtTapFwHg5iHVrbtnFsGzmZdaF4J4E17FNqAczv
      fSWjCPGOVztZ3GQNv6DpDuG55kZ8wCp3OcwjVh+VwY4vckGrtxrI3LOl1NF4qgkg
      vNFhMPwQchg0o3DKfecxqikLT3zu6zZL86lc+QIDAQABAoIBAHaXR+gIOZVFNawt
      gCA9Lo55WA8bDb6y9zcM/bPqq5L4WwxqTkJgqqu12ZZUCF5K0k94fvrzBtTLg+av
      O1X/L45bRlWVIwYAOdD+6cXkkjTrjxttxMd8DC8+2G9ljR+iAqcPPcHX5en0P49H
      WL0gwDwrYUP32zwAUT1RT40eDr72B10vsSbUdjAgCj8GUkLz4d5Qu1j6ZhRZ2DaW
      Z6iKzV6sBMH8rvMtlRSVDLK1upDzZr1YE10oGa8TiFvxfe5EXtnxa9VaTw4kuRL4
      R8A5PA96gyeBfhyjpGiG8w2Dhmc2bRbA7XcSM7q4q05uhoa3ynPGRTze6EzeSIlp
      Sz/uwwUCgYEA8wbfNeQ5R+vUcTyITbAk4tHL9v9e1zHxZ+Kbk6jOFFeMoT52iDmq
      jJ12Wjpi+Rf0UqWzmwxixXABIV9Mjl/78/lcTJWoAeTw9FaRR4Ni/qnKebSuAEUd
      atinbKfCgdX4rHEvd54mIB75tFy/qCcgdfmavA6rT4HYhHhZfehBhOsCgYEA0i0G
      q5iK2pIw5t1DXmU87jWgkcVLtzhtSp5tE3dYOf6NbOiuRiCOAObm7HrcVo+nk3y6
      8cKREgjQMz5H3BhVHQMuqzCVfpARFyOd/gthZ/dLtsgpNWLS0bO66Z0tUIkrWn+k
      2l0teulF8ItyPTSoLWBuLizWSK7BqJ2ONKibvKsCgYEA7UhkX8X5d5N21Sj5HIFD
      QoL81qj3/Lyyq2/B3yYOMCZbFIRcTx2eu7Ryfh5LzFHrJ1bKSjSJq6R0NhVKNijZ
      Y5iw2cW1SEQ0TxzGtEBAQ82b98DFs1XIJy5qKdiSPRqhthy879nl967Gt6dnKdMq
      CoYu4jagZPyuXojzN8+xSQkCgYBEd0B2A7Iv83GUsz1v8aDApJ2S/udkXzBTH3q+
      3aDS+5ZMhRvIYnB/4LgXDwrZ8+AODpLDkLM7Yb2ZA8/a5d5MHi5EvAXm/b1jgUnF
      aSWo/YkfmOK7rl6oy1i3I2mQk66Yw34LWFEpefY7nuFvCMlERuZ9ikOf17XkXLbn
      domNEwKBgQCR+bHxFqlaQ7Ji8ISdOVQw4I12gXZ2S+YSRlleVMncejk8PzqxsPUb
      HworxvqW/7+unMiNPeMhpRxLwsCURxxnDjqshkv0IGPz5TJPjM2FOjmJOGtUrT1C
      gk3BiK6VdNJ0aPZIKGU5coVNg4zJC9C3swPdK2y6QsccFN9dnP/uww==
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
      echo "branch1 - 10.10.2.5 -\$(timeout 3 ping -qc2 -W1 10.10.2.5 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
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
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null 10.10.2.5) - branch1 (10.10.2.5)"
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
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null g08-spoke3-d2cc.azurewebsites.net) - g08-spoke3-d2cc.azurewebsites.net"
      EOF
      chmod a+x /usr/local/bin/curl-dns
      
      # trace-ip
      
      cat <<EOF > /usr/local/bin/trace-ip
      echo -e "\n trace ip ...\n"
      echo -e "\nbranch1"
      echo -e "-------------------------------------"
      timeout 9 tracepath 10.10.2.5
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
