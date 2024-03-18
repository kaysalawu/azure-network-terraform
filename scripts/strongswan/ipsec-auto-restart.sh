#!/bin/bash

LOG_FILE="/var/log/ipsec-auto-restart.log"

connections=$(grep '^conn' /etc/ipsec.conf | grep -v '%default' | cut -d' ' -f2)

for conn in $connections; do
  if ! ipsec status | grep -q "$conn"; then
    echo "$(date): $conn is down. Attempting to restart..." >> "$LOG_FILE"
    ipsec down $conn
    ipsec up $conn
    echo "$(date): $conn restart command issued." >> "$LOG_FILE"
  fi
done
