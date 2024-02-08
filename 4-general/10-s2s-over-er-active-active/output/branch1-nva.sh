Section: IOS configuration
!-----------------------------------------
! IPSec
!-----------------------------------------
crypto ikev2 proposal AZURE-IKE-PROPOSAL
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE
proposal AZURE-IKE-PROPOSAL
match address local 10.10.1.9
!
crypto ikev2 keyring AZURE-KEYRING
peer 10.11.128.4
address 10.11.128.4
pre-shared-key changeme
peer 10.11.128.5
address 10.11.128.5
pre-shared-key changeme
peer 10.30.1.9
address 10.30.1.9
pre-shared-key changeme
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.10.1.9
match identity remote address 10.11.128.4 255.255.255.255
match identity remote address 10.11.128.5 255.255.255.255
match identity remote address 10.30.1.9 255.255.255.255
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
ip address 10.10.10.1 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.10.1.9
tunnel destination 10.11.128.4
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel1
ip address 10.10.10.5 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.10.1.9
tunnel destination 10.11.128.5
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel2
ip address 10.10.10.9 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.10.1.9
tunnel destination 10.30.1.9
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
!
!-----------------------------------------
! Interface
!-----------------------------------------
interface Loopback0
ip address 192.168.10.10 255.255.255.255
!
!-----------------------------------------
! Prefix Lists
!-----------------------------------------
ip prefix-list BLOCK_HUB_GW_SUBNET deny 10.11.128.0/24
ip prefix-list BLOCK_HUB_GW_SUBNET permit 0.0.0.0/0 le 32
!
!-----------------------------------------
! NAT
!-----------------------------------------
ip access-list extended NAT-ACL
permit ip 10.0.0.0 0.255.255.255 any
permit ip 172.16.0.0 0.15.255.255 any
permit ip 192.168.0.0 0.0.255.255 any
interface GigabitEthernet1
ip nat outside
ip nat inside
exit
ip nat inside source list NAT-ACL interface GigabitEthernet1 overload
!
ip route 0.0.0.0 0.0.0.0 10.10.1.1
ip route 10.11.128.14 255.255.255.255 Tunnel0
ip route 10.11.128.15 255.255.255.255 Tunnel1
ip route 192.168.30.30 255.255.255.255 Tunnel2
ip route 10.10.0.0 255.255.255.0 10.10.2.1
!
!-----------------------------------------
! Route Maps
!-----------------------------------------
route-map ONPREM permit 100
match ip address prefix-list all
set as-path prepend 65001 65001 65001
route-map AZURE permit 110
match ip address prefix-list all
route-map BLOCK_HUB_GW_SUBNET permit 120
match ip address prefix-list BLOCK_HUB_GW_SUBNET
!
!-----------------------------------------
! BGP
!-----------------------------------------
router bgp 65001
bgp router-id 192.168.10.10
neighbor 10.11.128.14 remote-as 65515
neighbor 10.11.128.14 ebgp-multihop 255
neighbor 10.11.128.14 soft-reconfiguration inbound
neighbor 10.11.128.14 update-source Loopback0
neighbor 10.11.128.14 route-map BLOCK_HUB_GW_SUBNET in
neighbor 10.11.128.14 route-map AZURE out
neighbor 10.11.128.15 remote-as 65515
neighbor 10.11.128.15 ebgp-multihop 255
neighbor 10.11.128.15 soft-reconfiguration inbound
neighbor 10.11.128.15 update-source Loopback0
neighbor 10.11.128.15 route-map BLOCK_HUB_GW_SUBNET in
neighbor 10.11.128.15 route-map AZURE out
neighbor 192.168.30.30 remote-as 65003
neighbor 192.168.30.30 ebgp-multihop 255
neighbor 192.168.30.30 soft-reconfiguration inbound
neighbor 192.168.30.30 update-source Loopback0
neighbor 192.168.30.30 route-map ONPREM out
network 10.10.0.0 mask 255.255.255.0
