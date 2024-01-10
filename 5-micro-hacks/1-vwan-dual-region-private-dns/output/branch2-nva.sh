Section: IOS configuration

crypto ikev2 proposal AZURE-IKE-PROPOSAL
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE
proposal AZURE-IKE-PROPOSAL
match address local 10.20.1.9
!
crypto ikev2 keyring AZURE-KEYRING
peer 20.242.238.248
address 20.242.238.248
pre-shared-key changeme
peer 20.242.238.183
address 20.242.238.183
pre-shared-key changeme
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.20.1.9
match identity remote address 20.242.238.248 255.255.255.255
match identity remote address 20.242.238.183 255.255.255.255
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
ip address 10.20.20.1 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.20.1.9
tunnel destination 20.242.238.248
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel1
ip address 10.20.20.5 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.20.1.9
tunnel destination 20.242.238.183
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Loopback0
ip address 192.168.20.20 255.255.255.255
!
ip access-list extended NAT-ACL
permit ip 10.20.0.0 0.0.0.255 any
interface GigabitEthernet2
ip nat inside
interface GigabitEthernet1
ip nat outside
exit
ip nat inside source list NAT-ACL interface GigabitEthernet1 overload
!
ip route 0.0.0.0 0.0.0.0 10.20.1.1
ip route 192.168.22.12 255.255.255.255 Tunnel0
ip route 192.168.22.13 255.255.255.255 Tunnel1
ip route 10.20.0.0 255.255.255.0 10.20.2.1
!
route-map ONPREM permit 100
match ip address prefix-list all
set as-path prepend 65002 65002 65002
route-map AZURE permit 110
match ip address prefix-list all
!
router bgp 65002
bgp router-id 192.168.20.20
neighbor 192.168.22.12 remote-as 65515
neighbor 192.168.22.12 ebgp-multihop 255
neighbor 192.168.22.12 soft-reconfiguration inbound
neighbor 192.168.22.12 update-source Loopback0
neighbor 192.168.22.12 route-map AZURE out
neighbor 192.168.22.13 remote-as 65515
neighbor 192.168.22.13 ebgp-multihop 255
neighbor 192.168.22.13 soft-reconfiguration inbound
neighbor 192.168.22.13 update-source Loopback0
neighbor 192.168.22.13 route-map AZURE out
network 10.20.0.0 mask 255.255.255.0
