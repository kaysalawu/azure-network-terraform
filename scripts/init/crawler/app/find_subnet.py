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
        raise Exception("Error getting IP address: " + stderr.decode('utf-8'))

def get_vnet_subnets():
    cmd = f"az network vnet subnet list --resource-group {RESOURCE_GROUP} --vnet-name {VNET_NAME} -o json"
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()
    if process.returncode == 0:
        subnets = json.loads(stdout.decode('utf-8'))
        subnets_list = []
        for subnet in subnets:
            if 'addressPrefix' in subnet:
                subnets_list.append((subnet['name'], subnet['addressPrefix']))
            elif 'addressPrefixes' in subnet:
                for prefix in subnet['addressPrefixes']:
                    subnets_list.append((subnet['name'], prefix))
        return subnets_list
    else:
        raise Exception("Error listing VNET subnets: " + stderr.decode('utf-8'))

def find_subnet_for_ip(ip_address):
    subnets = get_vnet_subnets()
    ip = ipaddress.ip_address(ip_address)
    for name, prefix in subnets:
        network = ipaddress.ip_network(prefix, strict=False)
        if ip in network:
            return name
    return None

def main():
    ip_address = sys.argv[1] if len(sys.argv) > 1 else get_ip_address()
    subnet_name = find_subnet_for_ip(ip_address)
    if subnet_name:
        print(subnet_name)
    else:
        print("None")

if __name__ == '__main__':
    main()
