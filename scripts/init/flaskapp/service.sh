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

sed -i "/#\$nrconf{restart} = 'i';/s/.*/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf || true

cat <<EOF > /etc/motd
################################################
         Docker Multiport Application
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
    echo " Step 0: Install packages"
    echo "*****************************************"
    apt-get update
    apt-get install -y python3-pip python3-dev tcpdump dnsutils net-tools nmap apache2-utils

    echo "*****************************************"
    echo " Step 1: Install docker"
    echo "*****************************************"
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    echo ""
    docker version
    docker compose version

    echo "*****************************************"
    echo " Step 2: Cleanup apt"
    echo "*****************************************"
    apt-get --purge -y autoremove
    apt-get clean
    echo "done!"
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
  docker ps
  echo ""
  echo "#####################"
  echo "netstat -tupanl|egrep \"80|8080|8081\"|grep -i listen"
  netstat -tupanl|egrep "80|8080|8081"|grep -i listen
}

systemd_config() {
  echo "**********************************************************"
  echo "STEP 4:  Systemd Service for flaskapp"
  echo "**********************************************************"
  echo "Create: /etc/systemd/system/flaskapp.service"
  cat <<EOF > /etc/systemd/system/flaskapp.service
  [Unit]
  Description=Script for flaskapp

  [Service]
  Type=oneshot
  ExecStart=-$init_dir/start.sh
  RemainAfterExit=true
  ExecStop=-$init_dir/stop.sh
  StandardOutput=journal

  [Install]
  WantedBy=multi-user.target
EOF
  cat /etc/systemd/system/flaskapp.service
  systemctl start flaskapp
  systemctl enable flaskapp
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
