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
          exit 0
      fi
      
      if [ $# -eq 3 ]; then
          RESOURCE_GROUP_NAME=$1
          VPN_GATEWAY_NAME=$2
          VPN_GATEWAY_IP=$3
      else
          source .env
      fi
      
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
      if [ -n "$VPN_GATEWAY_IP" ]; then
          sed -i "s/remote .* 443/remote $VPN_GATEWAY_IP 443/g" ./vpnClient/OpenVPN/vpnconfig.ovpn
      fi
      
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
      MIIEIDCCAwigAwIBAgIRANkFCo8FNQKZ+8Juzjkw8SAwDQYJKoZIhvcNAQELBQAw
      gY4xCzAJBgNVBAYTAlVLMRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25k
      b24xGjAYBgNVBAkTEW1wbHMgY2hpY2tlbiByb2FkMQ0wCwYDVQQKEwRkZW1vMRsw
      GQYDVQQLExJjbG91ZCBuZXR3b3JrIHRlYW0xFDASBgNVBAMTC3Aycy1yb290LWNh
      MB4XDTI0MDEyMjE0NTg1M1oXDTI1MDEyMTE0NTg1M1owgaUxCzAJBgNVBAYTAlVL
      MRAwDgYDVQQIEwdFbmdsYW5kMQ8wDQYDVQQHEwZMb25kb24xNTAWBgNVBAkTDyBu
      ZXR3b3JrIGF2ZW51ZTAbBgNVBAkTFDk5IG1wbHMgY2hpY2tlbiByb2FkMRMwEQYD
      VQQKEwpuZXR3b3JraW5nMRUwEwYDVQQLEwxuZXR3b3JrIHRlYW0xEDAOBgNVBAMT
      B2NsaWVudDEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCtAtyf0bVr
      Vz7USUFyg2IUTyGt4MRjOwaVVjueHyNeXPxYYaV7t2evouNfcu0bGKaapdyVYhQh
      cxWTgEismNHHPSPp6qs2VIEylAG49DKbzVJtBo0bmAF/bDqiSXSKUkJ/oa2dgKS8
      QIPYh/GTRTN/R/Dw+oOh5VuBgQpBWhujiajg6Ck2Xoan1wnYgtqb7/fMbEeuPGJv
      HtwUzAHPG9v9MIVjgR/IEdgSH3QhJIaP9Srv2mpZKRX/XaFBoZpYYp+1JRvDjOmP
      wfKUXF9znlMZ3N8x8FLlzRmKLi5NaCID0x4q975i9jAtKDQr9qXM5iPtVYBj774g
      QpWgnCOglX0xAgMBAAGjYDBeMA4GA1UdDwEB/wQEAwIFoDAdBgNVHSUEFjAUBggr
      BgEFBQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBR8qbX4
      WCEdHfxnohkQOLC1SEgrmTANBgkqhkiG9w0BAQsFAAOCAQEAiSP7XiM4SY2lHXMC
      8qkMiOJk1aloDvn5smMRZVOqvVhIYHc0ERKoHUvJu5M/BF3TAkhCRQS33ptXD5vn
      eWkX3/AmxZzMpHFjNXbf75tWNNf2WkqWOrFJcinu7KJ/wv9Dh/njg7odWBHuXspq
      f1w3P8tzqY/1scevbaiRIwtIv9hHCO47LlX5c/j7mkKSX0Dyboqh4oA/vDzTYHJL
      0Smsmkf5V1QDjQost/38ukVnn9+7L+dnwMbfH+43sZ91D2iG0Mpb1BU1GKFMJqX0
      skebnK99b1gsAKJn7Zw8XyaEWgyeF9Yjaa7sqTcb3d1EAhd2wwlT2eCviwPHl/Jb
      968JPA==
      -----END CERTIFICATE-----
  - path: /var/lib/azure/client1_key.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEowIBAAKCAQEArQLcn9G1a1c+1ElBcoNiFE8hreDEYzsGlVY7nh8jXlz8WGGl
      e7dnr6LjX3LtGximmqXclWIUIXMVk4BIrJjRxz0j6eqrNlSBMpQBuPQym81SbQaN
      G5gBf2w6okl0ilJCf6GtnYCkvECD2Ifxk0Uzf0fw8PqDoeVbgYEKQVobo4mo4Ogp
      Nl6Gp9cJ2ILam+/3zGxHrjxibx7cFMwBzxvb/TCFY4EfyBHYEh90ISSGj/Uq79pq
      WSkV/12hQaGaWGKftSUbw4zpj8HylFxfc55TGdzfMfBS5c0Zii4uTWgiA9MeKve+
      YvYwLSg0K/alzOYj7VWAY+++IEKVoJwjoJV9MQIDAQABAoIBAGi66sL0N1YbIjVv
      gubHEYApxsFy5m8LNBkCcmRthQOCVl9J/Nq/U0zG1czZzR4x9eh3rufez0DQYadA
      aL3SZGqvYCYhoDLrRKpRXhmP+XLG/7Zv2MtzYLS512SWAq4YzZhlTquhTBeJFkbl
      RB9aLKpH6lp1y2kdZh8m9gZJfaGonFSP/18tAnQCoKXhv94oXoBAhv3f5FA0/6mu
      0aQ38Z4gwfFsqEMl5+yZ8Ow3EKNrt6oZH8ytEK49CF8upMgOTPGxz7qSaOTEHNLA
      Q9AXoRaQXqLw58Xwcht6HQVSdJybE60YZwOwgDvwIUOPK+3lfv6ERMfCgD2Ijchp
      2ll1fgECgYEA2ihL5WNcT6tMNfEztOq1mEvR+/B80gKG0aypSwPChmO03WGmyuCe
      REs97VdUzCs4D+cO1zallFqUFGmy9BBAG8SSfWlafPZJVNMYcLcTlYcKiaVcAqS3
      k+WD/8yGC9YlxLZt5Bd9f6mmLElvborfk2mhAE2r8N6izW8ur6nEKTkCgYEAywXC
      Y6Ep9EhYGoVdQUJ+lslzESi4EI14MJ3VaZkOwK3Bc1Zehy+8Zd4Zc1aWmfVBf95o
      Snag2HPqL2DKvuob4BZeeEcVIaXUFR2I9lKj7NIM/w8Iz06BNT2LuH8HMPobgwLJ
      ODkLiFJ2o93hGGf1pvHZIbGNaqfVS0In5gfAS7kCgYEAin1yUNjWzSytYMESVhN5
      3IilcQ6l7pv0Aj9d6WUlpDK/qppHTBtz3V72nSkHh+UX3eCMp0rlqlwmDR9cn1uB
      lx8e78Zlz1Z6DwNDTKqsIAxuQBtdYcA3Wggl18l6fyEfMNWuxVG0Ncr41rx3pPE8
      JVS1BIBKWsq7BzdBp/pZsOECgYAujRSEaajIBWqGMjwuwYNrKafDsHV7/iQn6ZjM
      jLbQQUcRHiWwk6Z8KQ/m3VzM0mqBWkrJgCfjWbjBwkzat61KlXZ1176lp3NYoBwO
      duZ1X7hxJ05a0mJYBdOqqx3IAiEayiG/TX0ydc4URsTdJsEx1VR3IFIPuYnzpqil
      WvOhqQKBgFs7qjiRv3sf7Pk0rZIBeYsBPtP5Q8y645+HYmZXzbEB+ebIwqkfrxRo
      FUxaQ+yv3rlTUxz4eJpkV2okd/eBA+XYfVNlOtFQGS+ZRbm4QXBhgR7miOc+3Hq1
      nr6cYN6MUNOkaFywBSV9kp4hzk0OfMTP66hyDc5zc9DXjwIuFkBR
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
      echo "vm.hub1.eu.az.corp - \$(timeout 3 dig +short vm.hub1.eu.az.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 vm.hub1.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "vm.spoke1.eu.az.corp - \$(timeout 3 dig +short vm.spoke1.eu.az.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 vm.spoke1.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
      echo "vm.spoke2.eu.az.corp - \$(timeout 3 dig +short vm.spoke2.eu.az.corp | tail -n1) -\$(timeout 3 ping -qc2 -W1 vm.spoke2.eu.az.corp 2>&1 | awk -F'/' 'END{ print (/^rtt/? "OK "\$5" ms":"NA") }')"
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
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.hub1.eu.az.corp) - vm.hub1.eu.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null spoke3.p.hub1.eu.az.corp) - spoke3.p.hub1.eu.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke1.eu.az.corp) - vm.spoke1.eu.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke2.eu.az.corp) - vm.spoke2.eu.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null vm.spoke3.eu.az.corp) - vm.spoke3.eu.az.corp"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null icanhazip.com) - icanhazip.com"
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null g08-spoke3-c844.azurewebsites.net) - g08-spoke3-c844.azurewebsites.net"
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
  - echo 'RESOURCE_GROUP_NAME=G08RG' >> /var/lib/azure/.env
  - echo 'VPN_GATEWAY_NAME=G08-hub1-vpngw' >> /var/lib/azure/.env
