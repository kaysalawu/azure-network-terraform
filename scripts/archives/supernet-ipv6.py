import ipaddress

# Define a list of IPv6 networks to summarize
networks_to_aggregate = [
    ipaddress.ip_network('fd00:db8:11::/48'),
    ipaddress.ip_network('fd00:db8:22::/48'),
    ipaddress.ip_network('fd00:db8:10::/48'),
    ipaddress.ip_network('fd00:db8:20::/48'),
    ipaddress.ip_network('fd00:db8:30::/48'),
    ipaddress.ip_network('fd00:db8:1::/48'),
    ipaddress.ip_network('fd00:db8:6::/48')
]

# Collapse into a single or minimal number of supernets
summary_supernet = ipaddress.collapse_addresses(networks_to_aggregate)

# Output all possible supernets (usually there should just be one)
for network in summary_supernet:
    print(network)
