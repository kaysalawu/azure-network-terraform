Section: IOS configuration
!-----------------------------------------
! Prefix Lists
!-----------------------------------------
ip prefix-list BLOCK_HUB_GW_SUBNET deny 10.11.16.0/24
ip prefix-list BLOCK_HUB_GW_SUBNET permit 0.0.0.0/0 le 32
!
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
peer 4.207.76.218
address 4.207.76.218
pre-shared-key changeme
peer 4.207.76.173
address 4.207.76.173
pre-shared-key changeme
peer 10.30.1.9
address 10.30.1.9
pre-shared-key changeme
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.10.1.9
match identity remote address 4.207.76.218 255.255.255.255
match identity remote address 4.207.76.173 255.255.255.255
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
tunnel destination 4.207.76.218
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel1
ip address 10.10.10.5 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.10.1.9
tunnel destination 4.207.76.173
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
! NAT
!-----------------------------------------
!
!-----------------------------------------
! Static Routes
!-----------------------------------------
ip route 0.0.0.0 0.0.0.0 10.10.1.1
ip route 192.168.11.13 255.255.255.255 Tunnel0
ip route 192.168.11.12 255.255.255.255 Tunnel1
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
!
!-----------------------------------------
! BGP
!-----------------------------------------
router bgp 65001
bgp router-id 192.168.10.10
neighbor 192.168.11.13 remote-as 65515
neighbor 192.168.11.13 ebgp-multihop 255
neighbor 192.168.11.13 soft-reconfiguration inbound
neighbor 192.168.11.13 update-source Loopback0
neighbor 192.168.11.13 route-map AZURE out
neighbor 192.168.11.12 remote-as 65515
neighbor 192.168.11.12 ebgp-multihop 255
neighbor 192.168.11.12 soft-reconfiguration inbound
neighbor 192.168.11.12 update-source Loopback0
neighbor 192.168.11.12 route-map AZURE out
neighbor 192.168.30.30 remote-as 65003
neighbor 192.168.30.30 ebgp-multihop 255
neighbor 192.168.30.30 soft-reconfiguration inbound
neighbor 192.168.30.30 update-source Loopback0
neighbor 192.168.30.30 route-map ONPREM out
network 10.10.0.0 mask 255.255.255.0
