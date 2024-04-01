#!/bin/bash

# export SHELL=/bin/bash
# export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
# export HOME=/root
# export LANG=C.UTF-8
# export USER=root

# LOG_FILE="/var/log/ipsec-auto-restart.log"
# connections=$(grep '^conn' /etc/ipsec.conf | grep -v '%default' | awk '{print $2}')
# active_tunnel_found=false

# for conn in $connections; do
#   status=$(ipsec status | grep "$conn")
#   if [[ "$status" =~ ESTABLISHED ]]; then
#         echo "$(date): $conn: active." >> "$LOG_FILE"
#         active_tunnel_found=true
#     elif ! [[ "$status" =~ CONNECTING ]]; then
#         echo "$(date): $conn: down or inactive." >> "$LOG_FILE"
#     ipsec down $conn
#     ipsec up $conn
#     echo "$(date): $conn: restarted." >> "$LOG_FILE"

#     sleep 5
#     if [[ $(ipsec status | grep "$conn") =~ ESTABLISHED ]]; then
#       echo "$(date): $conn: active." >> "$LOG_FILE"
#       active_tunnel_found=true
#     else
#       echo "$(date): $conn: down or inactive." >> "$LOG_FILE"
#     fi
#   fi
# done

# if ! $active_tunnel_found; then
#   echo "$(date): No active tunnels found, restarting ipsec service..." >> "$LOG_FILE"
#   systemctl restart ipsec
#   echo "$(date): ipsec service restarted." >> "$LOG_FILE"
# fi

systemctl restart ipsec
