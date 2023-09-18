Section: IOS configuration

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
peer 20.71.19.236
address 20.71.19.236
pre-shared-key changeme
peer 20.71.19.63
address 20.71.19.63
pre-shared-key changeme
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.10.1.9
match identity remote address 20.71.19.236 255.255.255.255
match identity remote address 20.71.19.63 255.255.255.255
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
tunnel destination 20.71.19.236
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Tunnel1
ip address 10.10.10.5 255.255.255.252
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source 10.10.1.9
tunnel destination 20.71.19.63
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
interface Loopback0
ip address 192.168.10.10 255.255.255.255
!
ip route 0.0.0.0 0.0.0.0 10.10.1.1
ip route 10.11.7.5 255.255.255.255 Tunnel0
ip route 10.11.7.4 255.255.255.255 Tunnel1
ip route 10.10.0.0 255.255.255.0 10.10.2.1
!
route-map NEXT-HOP permit 100
match ip address prefix-list all
set as-path prepend 65001 65001 65001
!
router bgp 65001
bgp router-id 192.168.10.10
neighbor 10.11.7.5 remote-as 65515
neighbor 10.11.7.5 ebgp-multihop 255
neighbor 10.11.7.5 soft-reconfiguration inbound
neighbor 10.11.7.5 update-source Loopback0
neighbor 10.11.7.4 remote-as 65515
neighbor 10.11.7.4 ebgp-multihop 255
neighbor 10.11.7.4 soft-reconfiguration inbound
neighbor 10.11.7.4 update-source Loopback0
network 10.10.0.0 mask 255.255.255.0
