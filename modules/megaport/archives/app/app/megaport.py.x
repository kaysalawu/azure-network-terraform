import argparse
import base64
import requests
import sys
import os
import json

BASE_URL = "https://api.megaport.com"
AUTH_URL = "https://auth-m2m.megaport.com/oauth2/token"
USERNAME = os.getenv('TF_VAR_megaport_access_key')
PASSWORD = os.getenv('TF_VAR_megaport_secret_key')

def show_help():
    with open('help.txt', 'r') as file:
        help_text = file.read()
    print(help_text)

def get_access_token(resource_group, circuit_name):
    auth_credentials = base64.b64encode(f"{USERNAME}:{PASSWORD}".encode()).decode()

    access_token_response = requests.post(AUTH_URL, headers={
        "Authorization": f"Basic {auth_credentials}",
        "Content-Type": "application/x-www-form-urlencoded"
    }, data={"grant_type": "client_credentials"})

    access_token = access_token_response.json().get('access_token')
    if not access_token:
        sys.exit("MegaportAuth: Failed!")
    print("MegaportAuth: Success!")
    return access_token

def get_service_key(resource_group, circuit_name, BASE_URL, access_token):
    service_key = os.popen(f"az network express-route show --resource-group {resource_group} --name {circuit_name} --query \"serviceKey\" -o tsv").read().strip()
    if not service_key:
        sys.exit("ServiceKey: Failed!")
    print("ServiceKey: Success!")

    service_key_data_response = requests.get(f"{BASE_URL}/v2/secure/azure/{service_key}", headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}"
    })
    return service_key_data_response.json()

def get_mcr(product_type, product_name):
    response = requests.get(f"{BASE_URL}/v2/products?provisioningStatus=LIVE", headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}"
    })
    all_products = response.json().get("data")
    for product in all_products:
        if product.get("productType") == product_type and product.get("productName") == product_name:
            return product

def get_connections():
    response = requests.get(f"{BASE_URL}/v2/connections", headers={
        "Content-Type": "application

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

access_token = get_access_token(args.resource_group, args.circuit_name)
service_key_data = get_service_key(args.resource_group, args.circuit_name, BASE_URL, access_token)
mcr = get_mcr("MCR2", "salawu-poc08-mcr1")
connections = get_connections(mcr["productName"])
