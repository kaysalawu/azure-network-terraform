import argparse
import sys
from _megaport import *

parser = argparse.ArgumentParser(description="Manage MCR commands")
parser.add_argument('command', nargs='*', help='The command to execute (e.g., "list mcr")')
parser.add_argument('-g', '--resource-group', help='The name of the resource group.')
parser.add_argument('-c', '--circuit-name', help='The name of the circuit.')
parser.add_argument('-a', '--access-token', help='Get Megaport access token.')
parser.add_argument('-m', '--mcr', help='Megaport MCR name.')
parser.add_argument('-i', '--interactive', nargs='+', help='Interactive options such as MCR BGP, or VXC operations.')

args = parser.parse_args()
command_str = ' '.join(args.command)

def list_mcrs(search_string=None):
    megaport = Megaport()
    megaport.list_mcrs(search_string)

def list_connections(megaport):
    connections = megaport.get_connections()
    for index, connection in enumerate(connections, start=1):
        print(f"{index}. {connection.get('productName')}")

def get_access_token():
    megaport = Megaport()
    print("Access Token: ", megaport.access_token)

def show_mcr(megaport, product_name):
    mcr_details = megaport.get_mcr(product_name)
    if mcr_details:
        print("MCR Details:", json.dumps(mcr_details, indent=2))
    else:
        print("MCR not found.")

def interactive_bgp(megaport):
    megaport.interactive_bgp()

if args.interactive:
    if not args.mcr:
        print("Error: Interactive operations require -m parameter.")
        sys.exit(1)
    megaport = Megaport(args.mcr)
    for option in args.interactive:
        if option.lower() == "bgp":
            interactive_bgp(megaport)
        elif option.lower() == "vxc":
            print("VXC operation is not implemented yet.")
        else:
            print(f"Error: {option} is not a valid interactive option.")
elif command_str:
    if command_str == "list mcr":
        list_mcrs()
    elif command_str == "list connections":
        if not args.mcr:
            print("Error: list connections requires -m parameter.")
            sys.exit(1)
        megaport = Megaport(args.mcr)
        list_connections(megaport)
    elif command_str == "get access-token":
        get_access_token()
    elif command_str.startswith("show mcr"):
        if not args.mcr:
            print("Error: show mcr requires -m parameter.")
            sys.exit(1)
        product_name = command_str.split(" ")[2] if len(command_str.split(" ")) > 2 else None
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
