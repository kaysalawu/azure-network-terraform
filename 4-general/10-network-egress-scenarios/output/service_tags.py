import os
import sys
import json
import ipaddress

with open('service_tags.json', 'r') as file:
    data = json.load(file)

def locate_IP_range(ip_address):
    target_ip = ipaddress.ip_address(ip_address)
    matches = []

    for value in data['values']:
        for prefix in value['properties']['addressPrefixes']:
            if target_ip in ipaddress.ip_network(prefix):
                matches.append(f"   - {ipaddress.ip_network(prefix)} <-- {value['id']} ({value['properties']['region']})")

    for match in matches:
        print(match)

def main():
    if len(sys.argv) < 2:
        print("Usage: python service_tags.py <ip_address>")
        sys.exit(1)

    ip_address = sys.argv[1]
    locate_IP_range(ip_address)

if __name__ == "__main__":
    main()
