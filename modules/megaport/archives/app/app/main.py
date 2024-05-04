import argparse
import base64
import requests
import sys
import os
import json
from _megaport import *

def show_help(self):
    with open('help.txt', 'r') as file:
        help_text = file.read()
    print(help_text)

parser = argparse.ArgumentParser(add_help=False)
parser.add_argument('-g', '--resource-group')
parser.add_argument('-c', '--circuit-name')
parser.add_argument('-a', '--action')
parser.add_argument('-h', '--helper', action='store_true')

args = parser.parse_args()

if args.helper:
    show_help()
    sys.exit(0)

if not all([args.resource_group, args.circuit_name]):
    print("Error: Missing required arguments.")
    show_help()
    sys.exit(1)

print(f"ResourceGroup: {args.resource_group}")
print(f"CircuitName: {args.circuit_name}")

def get_service_key(resource_group, circuit_name):
    service_key = os.popen(f"az network express-route show --resource-group {resource_group} --name {circuit_name} --query \"serviceKey\" -o tsv").read().strip()
    if not service_key:
        sys.exit("ServiceKey: Failed!")
    print("ServiceKey: Success!")
    return service_key

service_key = get_service_key(args.resource_group, args.circuit_name)
megaport = Megaport(service_key)
# megaport.list_mcrs("salawu-poc08-mcr1")
mcr = megaport.get_mcr("salawu-poc08-mcr1")
connections = megaport.get_connections()
megaport.update_connection_bgp()

# service_key_data = get_service_key(args.resource_group, args.circuit_name, BASE_URL, access_token)
# mcr = get_mcr("MCR2", "salawu-poc08-mcr1")
# connections = get_connections(mcr["productName"])
