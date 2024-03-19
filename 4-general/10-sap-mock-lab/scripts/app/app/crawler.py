from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import SubscriptionClient
import requests
import socket
import subprocess

credential = DefaultAzureCredential()
token = credential.get_token("https://management.azure.com/.default").token

# check if management.azure.com is reachable
url = "https://management.azure.com/subscriptions?api-version=2020-01-01"
headers = {"Authorization": f"Bearer {token}"}
response = requests.get(url, headers=headers)
print(f"{response.status_code}: management.azure.com")

def run_bash_script(script):
    subprocess.run([script], shell=True)

run_bash_script('./crawler.sh')
