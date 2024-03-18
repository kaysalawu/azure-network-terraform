from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import SubscriptionClient
import requests

# Authenticate with Azure
credential = DefaultAzureCredential()
token = credential.get_token("https://management.azure.com/.default").token

# Test access to management.azure.com
url = "https://management.azure.com/subscriptions?api-version=2020-01-01"
headers = {"Authorization": f"Bearer {token}"}
response = requests.get(url, headers=headers)

print(f"{response.status_code}: management.azure.com")

# Function to dig endpoints using socket for IP resolution
import socket

def dig_endpoints(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
        for line in lines:
            line = line.strip()
            try:
                ip_address = socket.gethostbyname(line)
                print(f"{ip_address}: {line}")
            except socket.gaierror:
                print(f"Could not resolve {line}")

# Call dig_endpoints with the path to your file
dig_endpoints('targets.txt')
