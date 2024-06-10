import ipaddress
import sys

def get_first_usable_ip(subnet):
    return str(ipaddress.ip_network(subnet).network_address + 1)

if __name__ == "__main__":
    subnet = sys.argv[1]
    print(get_first_usable_ip(subnet))
