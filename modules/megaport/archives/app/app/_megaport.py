import argparse
import base64
import requests
import sys
import os
import json

class Megaport:
    def __init__(self, mcr_name=None, service_key=None, username=None, password=None):
        self.base_url = "https://api.megaport.com"
        self.auth_url = "https://auth-m2m.megaport.com/oauth2/token"
        self.username = os.getenv('TF_VAR_megaport_access_key')
        self.password = os.getenv('TF_VAR_megaport_secret_key')
        if not self.username or not self.password:
            raise ValueError("Username and password must be provided via environment.")
        self.access_token = self.get_access_token()
        self.mcr_name = mcr_name
        self.mcr = self.get_mcr()
        self.connections = None

    def list_mcrs(self, search_string=None):
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.access_token}"
        }
        response = requests.get(f"{self.base_url}/v2/products?provisioningStatus=LIVE", headers=headers)
        all_products = response.json().get("data")

        for product in all_products:
            if search_string:
                if search_string in product.get("productName"):
                    print(product.get("productName"))
            else:
                print(product.get("productName"))

    def get_access_token(self):
        auth_credentials = base64.b64encode(f"{self.username}:{self.password}".encode()).decode()
        access_token_response = requests.post(self.auth_url, headers={
            "Authorization": f"Basic {auth_credentials}",
            "Content-Type": "application/x-www-form-urlencoded"
        }, data={"grant_type": "client_credentials"})

        access_token = access_token_response.json().get('access_token')
        if not access_token:
            sys.exit("MegaportAuth: Failed!")
        print("MegaportAuth: Success!")
        return access_token

    def get_mcr(self):
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {self.access_token}"
        }
        response = requests.get(f"{self.base_url}/v2/products?provisioningStatus=LIVE", headers=headers)
        all_products = response.json().get("data")

        for product in all_products:
            if product.get("productType") == "MCR2" and product.get("productName") == self.mcr_name:
                return product

    def get_connections(self):
        self.connections = self.mcr.get("associatedVxcs")
        return (self.connections)

    def prompt_connection(self):
        if not self.connections:
            self.get_connections()
        print("\nAvailable Connections:")
        for idx, connection in enumerate(self.connections, 1):
            print(f"{idx}. {connection['productName']}")
        choice = input("Select a connection number to view details: ")
        try:
            selected_connection = self.connections[int(choice) - 1]
            return selected_connection
        except (IndexError, ValueError):
            print("Invalid selection.")

    def prompt_bgp_action(self):
        actions = ("1. Enable BGP", "2. Disable BGP")
        print("\nSelect BGP action:")
        for action in actions:
            print(action)
        choice = input("Select an action number: ")
        try:
            if int(choice) == 1:
                return "enable"
            elif int(choice) == 2:
                return "disable"
            else:
                print("Invalid selection.")
        except ValueError:
            print("Invalid selection.")

    def interactive_bgp(self):
        connection = self.prompt_connection()
        product_uid = connection['productUid']
        csp_connection = connection['resources']['csp_connection']

        for c in csp_connection:
            if c.get('connectType') == "VROUTER":
                update_data = {
                    "aEndConfig": {
                        "interfaces": c['interfaces']
                    }
                }

                for interface in update_data['aEndConfig']['interfaces']:
                    for bgpConnection in interface['bgpConnections']:
                        current_action = bgpConnection.get('shutdown')
                        print(f"(BGP shutdown is currently {current_action})")
                        action = self.prompt_bgp_action()
                        if action == "enable":
                            bgpConnection['shutdown'] = False
                        elif action == "disable":
                            bgpConnection['shutdown'] = True
                headers = {
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {self.access_token}"
                }
                response = requests.put(f"{self.base_url}/v3/product/vxc/{product_uid}", headers=headers, data=json.dumps(update_data))
                print(response.json()['message'])

