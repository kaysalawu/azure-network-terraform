import argparse
import sys
import os
from _megaport import *

def get_service_key(resource_group, circuit_name):
    service_key = os.popen(f"az network express-route show --resource-group {resource_group} --name {circuit_name} --query \"serviceKey\" -o tsv").read().strip()
    if not service_key:
        sys.exit("ServiceKey: Failed!")
    print("ServiceKey: Success!")
    return service_key

def list_mcrs(megaport):
    megaport.list_mcrs()

def list_connections(megaport):
    connections = megaport.get_connections()
    print(connections)

def get_access_token(megaport):
    print("Access Token: ", megaport.access_token)

def show_mcr(megaport, product_name):
    mcr_details = megaport.get_mcr(product_name)
    if mcr_details:
        print("MCR Details:", mcr_details)
    else:
        print("MCR not found.")

def interactive_bgp(megaport):
    megaport.interactive_bgp()

parser = argparse.ArgumentParser(description="Manage MCR commands")
parser.add_argument('command', nargs='?', help='The command to execute (e.g., "list mcr")')
parser.add_argument('-g', '--resource-group', help='The name of the resource group.')
parser.add_argument('-c', '--circuit-name', help='The name of the circuit.')
parser.add_argument('-m', '--mcr', required=True, help='Megport MCR name.')
parser.add_argument('-i', '--interactive', nargs='+', help='Interactive options such as BGP or VXC adjustments.')

args = parser.parse_args()

# service_key = get_service_key(args.resource_group, args.circuit_name)

if args.interactive:
    for option in args.interactive:
        if option.lower() == "bgp":
            megaport = Megaport(args.mcr)
            interactive_bgp(megaport)
        elif option.lower() == "vxc":
            print("VXC operation is not implemented yet.")
        else:
            print(f"Error: {option} is not a valid interactive option.")
elif args.command:
    if args.command == "list mcr":
        if not (args.resource_group and args.circuit_name):
            print("Error: list mcr requires -g and -c parameters.")
            sys.exit(1)
        megaport = Megaport(args.mcr)
        list_mcrs(megaport)
    elif args.command == "list connections":
        if not (args.resource_group and args.circuit_name):
            print("Error: list connections requires -g and -c parameters.")
            sys.exit(1)
        megaport = Megaport(args.mcr)
        list_connections(megaport)
    elif args.command == "get access token":
        get_access_token(megaport)
    elif args.command.startswith("show mcr"):
        product_name = args.command.split(" ")[1] if len(args.command.split(" ")) > 1 else None
        if not product_name:
            print("Error: show mcr requires an MCR product name.")
            sys.exit(1)
        megaport = Megaport(args.mcr)
        show_mcr(megaport, product_name)
    else:
        print("Error: Invalid or missing command.")
        sys.exit(1)
else:
    print("No command specified.")
    parser.print_help()
    sys.exit(1)

# service_key = get_service_key(args.resource_group, args.circuit_name)
# megaport = Megaport()
# # # megaport.list_mcrs("salawu-poc08-mcr1")
# mcr = megaport.get_mcr("salawu-poc08-mcr1")
# # connections = megaport.get_connections()
# megaport.interactive_connection_bgp()

# service_key_data = get_service_key(args.resource_group, args.circuit_name, BASE_URL, access_token)
# mcr = get_mcr("MCR2", "salawu-poc08-mcr1")
# connections = get_connections(mcr["productName"])
