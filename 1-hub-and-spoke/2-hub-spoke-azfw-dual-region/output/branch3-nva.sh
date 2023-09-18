Section: IOS configuration

crypto ikev2 proposal AZURE-IKE-PROPOSAL
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE
proposal AZURE-IKE-PROPOSAL
match address local 10.30.1.9
!
crypto ikev2 keyring AZURE-KEYRING
peer 4.231.153.234
address 4.231.153.234
pre-shared-key changeme
peer 4.231.153.233
address 4.231.153.233
pre-shared-key changeme
peer 20.86.218.158
address 20.86.218.158
pre-shared-key changeme
peer 20.86.220.112
address 20.86.220.112
pre-shared-key changeme
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.30.1.9
match identity remote address 4.231.153.234 255.255.255.255
match identity remote address 4.231.153.233 255.255.255.255
match identity remote address 20.86.218.158 255.255.255.255
match identity remote address 20.86.220.112 255.255.255.255
authentication remote pre-share
authentication local pre-share
keyring local AZURE-KEYRING
lifetime 28800
dpd 10 5 on-demand
!
crypto ipsec transform-set AZURE-IPSEC-TRANSFORM-SET esp-gcm 256
mode tunnel
!
crypto ipsec profile AZURE-IPSEC-PROFILE
set transform-set AZURE-IPSEC-TRANSFORM-SET
set ikev2-profile AZURE-IKE-PROPOSAL
set security-association lifetime seconds 3600
!
interface Tunnel0
ip address 10.30.30.1 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.30.1.9
tunnel destination 4.231.153.234
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel1
ip address 10.30.30.5 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.30.1.9
tunnel destination 4.231.153.233
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel2
ip address 10.30.30.9 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.30.1.9
tunnel destination 20.86.218.158
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel3
ip address 10.30.30.13 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.30.1.9
tunnel destination 20.86.220.112
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Loopback0
ip address 192.168.30.30 255.255.255.255
!
ip route 0.0.0.0 0.0.0.0 10.30.1.1
ip route 10.22.7.5 255.255.255.255 Tunnel0
ip route 10.22.7.4 255.255.255.255 Tunnel1
ip route 10.11.7.5 255.255.255.255 Tunnel2
ip route 10.11.7.4 255.255.255.255 Tunnel3
ip route 10.30.0.0 255.255.255.0 10.30.2.1
!
route-map NEXT-HOP permit 100
match ip address prefix-list all
set as-path prepend 65003 65003 65003
!
router bgp 65003
bgp router-id 192.168.30.30
neighbor 10.22.7.5 remote-as 65515
neighbor 10.22.7.5 ebgp-multihop 255
neighbor 10.22.7.5 soft-reconfiguration inbound
neighbor 10.22.7.5 update-source Loopback0
neighbor 10.22.7.4 remote-as 65515
neighbor 10.22.7.4 ebgp-multihop 255
neighbor 10.22.7.4 soft-reconfiguration inbound
neighbor 10.22.7.4 update-source Loopback0
neighbor 10.11.7.5 remote-as 65515
neighbor 10.11.7.5 ebgp-multihop 255
neighbor 10.11.7.5 soft-reconfiguration inbound
neighbor 10.11.7.5 update-source Loopback0
neighbor 10.11.7.4 remote-as 65515
neighbor 10.11.7.4 ebgp-multihop 255
neighbor 10.11.7.4 soft-reconfiguration inbound
neighbor 10.11.7.4 update-source Loopback0
network 10.30.0.0 mask 255.255.255.0
