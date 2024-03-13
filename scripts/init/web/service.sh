#! /bin/bash

set -e

base_dir=$(pwd)
init_dir="${INIT_DIR}"
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
