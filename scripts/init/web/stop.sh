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
