Section: IOS configuration

crypto ikev2 proposal AZURE-IKE-PROPOSAL
encryption aes-cbc-256
integrity sha1
group 2
!
crypto ikev2 policy AZURE-IKE-PROFILE
proposal AZURE-IKE-PROPOSAL
match address local ${INT_ADDR}
!
crypto ikev2 keyring AZURE-KEYRING
%{~ for v in TUNNELS }
peer ${v.ipsec.peer_ip}
address ${v.ipsec.peer_ip}
pre-shared-key ${v.ipsec.psk}
%{~ endfor }
!
crypto ikev2 profile AZURE-IKE-PROPOSAL
match address local ${INT_ADDR}
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
interface Loopback0
ip address ${LOOPBACK0} 255.255.255.255
%{~ for k,v in LOOPBACKS }
interface ${k}
ip address ${v} 255.255.255.255
%{~ endfor }
!
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
%{~ for route in STATIC_ROUTES }
ip route ${route.network} ${route.mask} ${route.next_hop}
%{~ endfor }
!
%{~ for x in ROUTE_MAPS }
route-map ${x.name} ${x.action} ${x.rule}
%{~ for y in x.commands }
${y}
%{~ endfor }
%{~ endfor }
!
router bgp ${LOCAL_ASN}
bgp router-id ${INT_ADDR}
%{~ for x in BGP_SESSIONS }
neighbor ${x.peer_ip} remote-as ${x.peer_asn}
%{~ if try(x.ebgp_multihop, false) }
neighbor ${x.peer_ip} ebgp-multihop 255
%{~ endif }
neighbor ${x.peer_ip} soft-reconfiguration inbound
%{~ if try(x.as_override, false) }
neighbor ${x.peer_ip} as-override
%{~ endif }
%{~ if try(x.next_hop_self, false) }
neighbor ${x.peer_ip} next-hop-self
%{~ endif }
%{~ if try(x.source_loopback, false) }
neighbor ${x.peer_ip} update-source Loopback0
%{~ endif }
%{~ if x.route_map != {} }
neighbor ${x.peer_ip} route-map ${x.route_map.name} ${x.route_map.direction}
%{~ endif }
%{~ endfor }
%{~ for net in BGP_ADVERTISED_NETWORKS }
network ${net.network} mask ${net.mask}
%{~ endfor }
