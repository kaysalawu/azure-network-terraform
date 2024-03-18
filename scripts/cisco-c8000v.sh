Section: IOS configuration
!-----------------------------------------
! Prefix Lists
!-----------------------------------------
%{~ for command in PREFIX_LISTS }
${command}
%{~ endfor }
!
!-----------------------------------------
! IPSec
!-----------------------------------------
%{~ if TUNNELS != [] }
crypto ikev2 proposal AZURE-IKE-PROPOSAL
encryption aes-cbc-256
integrity sha1
group 14
!
crypto ikev2 policy AZURE-IKE-PROFILE
proposal AZURE-IKE-PROPOSAL
match address local ${CRYPTO_ADDR}
!
crypto ikev2 keyring AZURE-KEYRING
%{~ for v in TUNNELS }
peer ${v.ipsec.peer_ip}
address ${v.ipsec.peer_ip}
pre-shared-key ${v.ipsec.psk}
%{~ endfor }
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local ${CRYPTO_ADDR}
%{~ for v in TUNNELS }
match identity remote address ${v.ipsec.peer_ip} 255.255.255.255
%{~ endfor }
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
%{~ for v in TUNNELS }
interface ${v.ike.name}
ip address ${v.ike.address} ${v.ike.mask}
tunnel mode ipsec ipv4
ip tcp adjust-mss 1350
tunnel source ${v.ike.source}
tunnel destination ${v.ike.dest}
tunnel protection ipsec profile AZURE-IPSEC-PROFILE
!
%{~ endfor }
%{~ endif }
!
!-----------------------------------------
! Interface
!-----------------------------------------
interface Loopback0
ip address ${LOOPBACK0} 255.255.255.255
%{~ for k,v in LOOPBACKS }
interface ${k}
ip address ${v} 255.255.255.255
%{~ endfor }
!
!-----------------------------------------
! NAT
!-----------------------------------------
%{~ if NAT_ACL != [] }
ip access-list extended NAT-ACL
%{~ for command in NAT_ACL }
${command}
%{~ endfor }
interface GigabitEthernet2
ip nat inside
interface GigabitEthernet1
ip nat outside
exit
ip nat inside source list NAT-ACL interface GigabitEthernet1 overload
%{~ endif }
!
!-----------------------------------------
! Static Routes
!-----------------------------------------
%{~ for route in STATIC_ROUTES }
ip route ${route.network} ${route.mask} ${route.next_hop}
%{~ endfor }
!
!-----------------------------------------
! Route Maps
!-----------------------------------------
%{~ for command in ROUTE_MAPS }
${command}
%{~ endfor }
!
!-----------------------------------------
! BGP
!-----------------------------------------
router bgp ${LOCAL_ASN}
bgp router-id ${LOOPBACK0}
%{~ for s in BGP_SESSIONS }
neighbor ${s.peer_ip} remote-as ${s.peer_asn}
%{~ if try(s.ebgp_multihop, false) }
neighbor ${s.peer_ip} ebgp-multihop 255
%{~ endif }
neighbor ${s.peer_ip} soft-reconfiguration inbound
%{~ if try(s.as_override, false) }
neighbor ${s.peer_ip} as-override
%{~ endif }
%{~ if try(s.next_hop_self, false) }
neighbor ${s.peer_ip} next-hop-self
%{~ endif }
%{~ if try(s.source_loopback, false) }
neighbor ${s.peer_ip} update-source Loopback0
%{~ endif }
%{~ if s.route_maps != [] }
%{~ for map in s.route_maps }
neighbor ${s.peer_ip} route-map ${map.name} ${map.direction}
%{~ endfor }
%{~ endif }
%{~ endfor }
%{~ for net in BGP_ADVERTISED_NETWORKS }
network ${net.network} mask ${net.mask}
%{~ endfor }

license boot level network-advantage addon dna-advantage
do wr mem
do reload
