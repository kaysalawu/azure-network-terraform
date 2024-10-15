#!bin/bash

cat <<EOF >/usr/local/bin/playz
#! /bin/bash
echo "--------------------------------------"
echo "user1"
echo "--------------------------------------"
curl --max-time 1 http://${FQDN_USER1}:7474 && echo
curl -k --max-time 1 https://${FQDN_USER1}:7473 && echo
bash -c 'echo | nc ${FQDN_USER1} 7687'
echo
echo "--------------------------------------"
echo "user2"
echo "--------------------------------------"
curl --max-time 1 http://${FQDN_USER2}:7474 && echo
curl -k --max-time 1 https://${FQDN_USER2}:7473 && echo
bash -c 'echo | nc ${FQDN_USER2} 7687'
echo
EOF
chmod a+x /usr/local/bin/playz

cat <<EOF >/usr/local/bin/floodz
#! /bin/bash
while true; do
  echo "--------------------------------------"
  echo "user1"
  echo "--------------------------------------"
  siege -c10 -t10S http://${FQDN_USER1}:7474
  siege -c10 -t10S https://${FQDN_USER1}:7473
  echo
  echo "--------------------------------------"
  echo "user2"
  echo "--------------------------------------"
  timeout 1 siege -c10 -t10S http://${FQDN_USER2}:7474
  timeout 1 siege -c10 -t10S https://${FQDN_USER2}:7473
  sleep 1
done
EOF
chmod a+x /usr/local/bin/floodz || true
