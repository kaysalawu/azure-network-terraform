import os
import sys
import ipaddress
from azure.identity import DefaultAzureCredential
from azure.mgmt.network import NetworkManagementClient

SUBSCRIPTION_ID = os.getenv('SUBSCRIPTION_ID')

def locate_IP_range(ip_address, location):
    client = NetworkManagementClient(
        credential=DefaultAzureCredential(),
        subscription_id=SUBSCRIPTION_ID
    )

    response = client.service_tags.list(
        location=location,
    )

    target_ip = ipaddress.ip_address(ip_address)
    matches = []

    for value in response.values:
        for prefix in value.properties.address_prefixes:
            if target_ip in ipaddress.ip_network(prefix):
                matches.append(f"  - {ipaddress.ip_network(prefix)} <-- {value.id} ({value.properties.region})")

    for match in matches:
        print(match)

def main():
    if len(sys.argv) < 3:
        print("Usage: python service_tags.py <ip_address> <location>")
        sys.exit(1)

    ip_address = sys.argv[1]
    location = sys.argv[2] if len(sys.argv) > 2 else "westeurope"
    print(f"* Searching for service tags ({ip_address})")
    locate_IP_range(ip_address, location)

if __name__ == "__main__":
    main()
