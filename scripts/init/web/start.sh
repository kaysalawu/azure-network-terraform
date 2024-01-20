#!/bin/bash

set -e

base_dir=$(pwd)
init_dir="${INIT_DIR}"
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
