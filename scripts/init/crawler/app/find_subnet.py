import os
import ipaddress
import subprocess
import json
import sys

RESOURCE_GROUP = os.getenv('RESOURCE_GROUP')
VNET_NAME = os.getenv('VNET_NAME')

def get_ip_address():
    cmd = "hostname -I | awk '{print $1}'"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()
    if process.returncode == 0:
        return stdout.decode('utf-8').strip()
    else:
        raise Exception("Error getting eth0 IP address: " + stderr.decode('utf-8'))

def get_vnet_subnets():
    cmd = f"az network vnet subnet list --resource-group {RESOURCE_GROUP} --vnet-name {VNET_NAME} -o json"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()
    if process.returncode == 0:
        subnets = json.loads(stdout.decode('utf-8'))
        return [(subnet['name'], subnet['addressPrefix']) for subnet in subnets]
    else:
        raise Exception("Error listing VNET subnets: " + stderr.decode('utf-8'))

def find_subnet_for_ip(ip_address):
    subnets = get_vnet_subnets()
    ip = ipaddress.ip_address(ip_address)
    for name, addressPrefix in subnets:
        if ip in ipaddress.ip_network(addressPrefix):
            return name, addressPrefix
    return None, None

def main():
    ip_address = get_ip_address()
    subnet_name, addressPrefix = find_subnet_for_ip(ip_address)
    if subnet_name:
        print(subnet_name)
    else:
        print(None)

if __name__ == '__main__':
    main()
