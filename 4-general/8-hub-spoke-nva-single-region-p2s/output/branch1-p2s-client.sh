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
      
      if [ $# -eq 2 ]; then
          RESOURCE_GROUP_NAME=$1
          VPN_GATEWAY_NAME=$2
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
      MIIEHzCCAwegAwIBAgIQWhrok+UnLkL3tHXnr82brTANBgkqhkiG9w0BAQsFADCB
      jjELMAkGA1UEBhMCVUsxEDAOBgNVBAgTB0VuZ2xhbmQxDzANBgNVBAcTBkxvbmRv
      bjEaMBgGA1UECRMRbXBscyBjaGlja2VuIHJvYWQxDTALBgNVBAoTBGRlbW8xGzAZ
      BgNVBAsTEmNsb3VkIG5ldHdvcmsgdGVhbTEUMBIGA1UEAxMLcDJzLXJvb3QtY2Ew
      HhcNMjQwMTIyMDkxMjM5WhcNMjUwMTIxMDkxMjM5WjCBpTELMAkGA1UEBhMCVUsx
      EDAOBgNVBAgTB0VuZ2xhbmQxDzANBgNVBAcTBkxvbmRvbjE1MBYGA1UECRMPIG5l
      dHdvcmsgYXZlbnVlMBsGA1UECRMUOTkgbXBscyBjaGlja2VuIHJvYWQxEzARBgNV
      BAoTCm5ldHdvcmtpbmcxFTATBgNVBAsTDG5ldHdvcmsgdGVhbTEQMA4GA1UEAxMH
      Y2xpZW50MTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANNWrOSWP5Dm
      legnWHa1MJVuWtmpvX5QRctMUjhAiiRU+WtmtGiSO4I7nWBwa+AmwIW7woQOOHui
      DmAaIrOCTZFl16pArqJ3rxT0rJZPBjrDnJ16aH4DmBan7guT/b+5P78JQNw20RAU
      z0G5Hy3w6yV5SH1r92isQytxrK/QGLHPypD1eH29+a2zp3HGDHlb1mmEEbpt11+w
      pVlCuYnwJa6QxRYlbEGlTT0u8gTjhjGSJMOcPbqZjI3AI3cZ48UzaPavIcqUPk+7
      8Qgq8TlmUHrybuvFHohC4akfX0yfq1/TX5OChmYcdl9NX2xmOVzN6kTMEsoMeR4n
      T4MnTHqCcwcCAwEAAaNgMF4wDgYDVR0PAQH/BAQDAgWgMB0GA1UdJQQWMBQGCCsG
      AQUFBwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFIOIG9wZ
      BRr3a6E8U/uru47rrrvpMA0GCSqGSIb3DQEBCwUAA4IBAQAY69LewcQo/MrOXRzw
      TS11wGd4IJhTTysdY3tgcs+yOjmWNyw57TP7NvbX4wRgTxqjW7VNmVB1AWbCHMWb
      2mB1AQoT1T3/sKo8NklGDr85Gngk1vFWKB5iI85XvPGFP3xWs6wREMgP/L95ChAU
      yxH16Dx+lvodtZVNSkbsxPEgKlDU1JVQlUoATbZyBnSNevgQzDnKAw/y3dBqnCIh
      bU+W7PItqw2+8WEgRY9tcH3PC2Mo4YulQ9Bnt9ig+ZZUzjgzJt0rVbriEViQWhQA
      +V3TuIOn2LxMNlXLNkAwYEtGm+FCbIh0MS1eKqZb7r7L5Y8u2rMQwSMsWtlJ4Kx3
      wkun
      -----END CERTIFICATE-----
  - path: /var/lib/azure/client1_key.pem
    owner: root
    permissions: 0400
    content: |
      -----BEGIN RSA PRIVATE KEY-----
      MIIEpgIBAAKCAQEA01as5JY/kOaV6CdYdrUwlW5a2am9flBFy0xSOECKJFT5a2a0
      aJI7gjudYHBr4CbAhbvChA44e6IOYBois4JNkWXXqkCuonevFPSslk8GOsOcnXpo
      fgOYFqfuC5P9v7k/vwlA3DbREBTPQbkfLfDrJXlIfWv3aKxDK3Gsr9AYsc/KkPV4
      fb35rbOnccYMeVvWaYQRum3XX7ClWUK5ifAlrpDFFiVsQaVNPS7yBOOGMZIkw5w9
      upmMjcAjdxnjxTNo9q8hypQ+T7vxCCrxOWZQevJu68UeiELhqR9fTJ+rX9Nfk4KG
      Zhx2X01fbGY5XM3qRMwSygx5HidPgydMeoJzBwIDAQABAoIBAQDTKHIc/wZKOCol
      yFI6YXVGiPmbK17bO0dRBlPMQqgD/ycqqXauWRW+XOQ0vH78epu3w09p9G95EAV+
      /f4YD6SDFxex02jpid3UeVeL4y9dPZ9ZNTn8Voj6chWFWfuaOXS44nz8yoR+pdwj
      Vd0SYPoB+jl0n5CW9C801CJvk+NonFz8V/uFm3WlhvwrLnzoHJH1aEuV2CEA3BCQ
      X6ka+FhGRV/71lM7fsSgHKZqosT9srKlnjyN4aga7ojZtGO/xo2819ve7FBTXRyK
      3PDwW6YAJk9mZ0OLIReCBt7hBTQNMaxnb6vX6qUKEK3h20zhIaS5XTZJ3NGuUkqI
      IrO+CumJAoGBAN3gT5aFC0cJoCbbmIKbxP93oj2X6QpAtAfOgy6kE60RTCGQjFXi
      /8M4e4idWZ3arrXpRnrQ/EOSLfWPXLXIjF9rL6CziIxKKX5HBKsNlvVZAlhgWjmH
      XDOoh8HlpQfGIK2sorWUgr1oyHWDYMw9NEUPjOY9H3sInBJeoM2vtWmrAoGBAPPX
      ekG7rpuCHpNFBnJg8ZVe0PqFoGEyz85904q3MP6HbEvJiV/soQruhF7E98tSL7vm
      koHKgWQAyakK9IFraYfROuOib3U01Cn3iXmuk9z+ChCTa/NIk3F7eKLXQa3KfXPd
      b7Z0WTMlDzGr5xzf7XFbGV7GpEjrezrZmypa6lgVAoGBAIjxo+3hXB6SYFjbfPxQ
      LH0JWAfwNRPw761J10n4V3Sgkn68+wEfxIC34fdmNyPpD6CTxL6VMr56AQfpXm2M
      xKc4PwNPDF6af5XDO6xgDOaN85ackdOkKlJwGKqilQOBVDYdsaelbDR/8gol9p7Y
      v+RIPsz0uPN1Uu87nMCXTL9VAoGBAMfoc0mqtda2EZ0JLOTex5B/IHMS1E57mtSe
      YazKzTcPDWEAxEhJNipBK3KKpuAg7BNvT9NqkzPKVYnp+lSUG/uGNHJlPF1pxzr0
      vtdsobq+5r96LTlR2ddis59FPIpfhQRVmX2K24pLqq49UYdhqkeRuTXzQsKpk+jG
      eCh8Sr2VAoGBAK1O0INkU2h3B2xWfmJe8lep4LlSfe/4xPyk1VCG61ADuyoVuYRm
      WgMMllzO29FyfNJugNJTiruosYMnQBiLWdYMSmJqsbHDGGGMEf65belA6BzrWsfg
      NPOqUcNOuyQnWDVbiMdrFTk0FlWmKzyzf7r6gVKuxpUwPf1qTg5pPjBv
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
      echo  "\$(timeout 4 curl -kL --max-time 2.0 -H 'Cache-Control: no-cache' -w "%{http_code} (%{time_total}s) - %{remote_ip}" -s -o /dev/null g08-spoke3-801b.azurewebsites.net) - g08-spoke3-801b.azurewebsites.net"
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
  - echo 'RESOURCE_GROUP_NAME=G08RG' >> /var/lib/azure/.env
  - echo 'VPN_GATEWAY_NAME=G08-hub1-vpngw' >> /var/lib/azure/.env
