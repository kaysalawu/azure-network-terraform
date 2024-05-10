import argparse
import sys
from _megaport import *

parser = argparse.ArgumentParser(description="Manage MCR commands")
parser.add_argument('command', nargs='*', help='The command to execute (e.g., "list mcr")')
parser.add_argument('-q', '--query', help='Query string for searching specific details.')
parser.add_argument('-g', '--resource-group', help='The name of the resource group.')
parser.add_argument('-c', '--circuit-name', help='The name of the circuit.')
parser.add_argument('-v', '--vxc', help='The name of the vxc connection.')
parser.add_argument('-a', '--access-token', help='Get Megaport access token.')
parser.add_argument('-m', '--mcr', help='Megaport MCR name.')
parser.add_argument('-i', '--interactive', nargs='+', help='Interactive options such as MCR BGP, or VXC operations.')

args = parser.parse_args()
command_str = ' '.join(args.command)

def list_mcrs(search_string=None):
    megaport = Megaport()
    megaport.list_mcrs(search_string)

def list_connections(mcr_name, query_string=None):
    megaport = Megaport(mcr_name)
    connections = megaport.get_connections()
    for index, connection in enumerate(connections, start=1):
        print(f"{index}. {connection.get('productName')}")

def get_access_token():
    megaport = Megaport()
    print("Access Token: ", megaport.access_token)

def show_mcr(mcr_name, query_string=None):
    megaport = Megaport(mcr_name)
    mcr_details = megaport.get_mcr()
    if mcr_details:
        print("MCR Details:", json.dumps(mcr_details, indent=2))
    else:
        print("MCR not found.")

def bgp_interactive(mcr_name):
    megaport = Megaport(mcr_name)
    megaport.bgp_interactive()

def bgp_update(mcr_name, connection_name, action):
    megaport = Megaport(mcr_name)
    megaport.bgp_update(connection_name, action)

if args.interactive:
    if not args.mcr:
        print("Error: Interactive operations require -m parameter.")
        sys.exit(1)
    for option in args.interactive:
        if option.lower() == "bgp":
            bgp_interactive(args.mcr)
        elif option.lower() == "vxc":
            print("VXC operation is not implemented yet.")
        else:
            print(f"Error: {option} is not a valid interactive option.")
elif command_str:
    if command_str == "list mcr":
        list_mcrs(args.query)
    elif command_str == "list connections":
        if not args.mcr:
            print("Error: list connections requires -m parameter.")
            sys.exit(1)
        list_connections(args.mcr, args.query)
    elif command_str == "get access token":
        get_access_token()
    elif command_str == "show mcr":
        if not args.mcr:
            print("Error: show mcr requires -m parameter.")
            sys.exit(1)
        show_mcr(args.mcr, args.query)
    elif command_str == "bgp enable":
        if not args.mcr and not args.vxc:
            print("Error: bgp enable requires -m parameter.")
            sys.exit(1)
        bgp_update(args.mcr, args.vxc, "enable")
    elif command_str == "bgp disable":
        if not args.mcr and not args.vxc:
            print("Error: bgp disable requires -m parameter.")
            sys.exit(1)
        bgp_update(args.mcr, args.vxc, "disable")
    else:
        print("Error: Invalid or missing command.")
        sys.exit(1)
else:
    print("No command specified.")
    parser.print_help()
    sys.exit(1)