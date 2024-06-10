import argparse
import sys
from _megaport import *

parser = argparse.ArgumentParser(
    description="Manage MCR commands. Set environment variables TF_VAR_megaport_access_key and TF_VAR_megaport_secret_key before running any commands"
)
parser.add_argument('command', nargs='*', help='The command to execute (e.g., "list mcr")')
parser.add_argument('-q', '--query', help='Query string for searching specific details.')
parser.add_argument('-o', '--output', help='Output format (e.g. "--output json", "-o table").')
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

def show_routes(mcr_name, query_string=None):
    megaport = Megaport(mcr_name)
    mcr_routes = megaport.get_routes()
    if mcr_routes:
        print(display_routes(mcr_routes))
    else:
        print("MCR not found.")

def display_routes(routes):
    header = f"\n{'Prefix':<18}{'BgpType':<12}{'NextHop':<16}{'NextHopVxc':<18}{'AsPath'}"
    divider = f"{'-------':<18}{'--------':<12}{'---------':<16}{'------------':<18}{'-------'}"
    print(header)
    print(divider)
    for route in routes:
        best = "*" if route["best"] else ""
        prefix = f'{route["prefix"]}{best}'
        bgp_type = "eBGP" if route["external"] else "iBGP"
        next_hop_ip = route["nextHop"]["ip"]
        next_hop_vxc = route["nextHop"]["vxc"]["name"]
        as_path = route["asPath"]
        print(f"{prefix:<18}{bgp_type:<12}{next_hop_ip:<16}{next_hop_vxc:<18}{as_path}")

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
    elif command_str == "show routes":
        if not args.mcr:
            print("Error: show mcr requires -m parameter.")
            sys.exit(1)
        show_routes(args.mcr, args.query)
    elif command_str == "bgp enable":
        if not (args.mcr and args.vxc):
            print("Error: bgp enable requires --mcr and -vcx parameters.")
            sys.exit(1)
        bgp_update(args.mcr, args.vxc, "enable")
    elif command_str == "bgp disable":
        if not (args.mcr and args.vxc):
            print("Error: bgp disable requires --mcr and -vcx parameters.")
            sys.exit(1)
        bgp_update(args.mcr, args.vxc, "disable")
    else:
        print("Error: Invalid or missing command.")
        sys.exit(1)
else:
    print("No command specified.")
    parser.print_help()
    sys.exit(1)
