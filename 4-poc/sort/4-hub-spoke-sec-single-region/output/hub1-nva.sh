Section: IOS configuration

crypto ikev2 proposal AZURE-IKE-PROPOSAL 
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE 
proposal AZURE-IKE-PROPOSAL
match address local 10.11.1.9
!
crypto ikev2 keyring AZURE-KEYRING
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local 10.11.1.9
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
interface Loopback0
ip address 10.11.11.11 255.255.255.255
interface Loopback1
ip address 10.11.2.99 255.255.255.255
!
ip route 0.0.0.0 0.0.0.0 10.11.1.1
!
!
router bgp 65000
bgp router-id 10.11.1.9
