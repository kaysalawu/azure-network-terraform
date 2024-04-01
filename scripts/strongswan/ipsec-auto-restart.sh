#!/bin/bash

export SHELL=/bin/bash
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin
export HOME=/root
export LANG=C.UTF-8
export USER=root

LOG_FILE="/var/log/ipsec-auto-restart.log"
connections=$(grep '^conn' /etc/ipsec.conf | grep -v '%default' | awk '{print $2}')
all_tunnels_active=true

for conn in $connections; do
  status=$(ipsec status | grep "$conn")
  if ! [[ "$status" =~ ESTABLISHED ]]; then
        all_tunnels_active=false
        echo "$(date): $conn: down or inactive." >> "$LOG_FILE"
    ipsec down $conn
    ipsec up $conn
    echo "$(date): $conn: restarting." >> "$LOG_FILE"
else
      echo "$(date): $conn: active." >> "$LOG_FILE"
        fi
done

if ! $all_tunnels_active; then
  echo "$(date): Not all tunnels active, restarting ipsec service..." >> "$LOG_FILE"
  systemctl restart ipsec
  echo "$(date): ipsec service restarted." >> "$LOG_FILE"
fi
