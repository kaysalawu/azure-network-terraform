import os
import socket
from fastapi import APIRouter, Request, HTTPException

router = APIRouter()

hostname = socket.gethostname()
ipv4_address = socket.gethostbyname(hostname)

try:
    ipv6_address = socket.getaddrinfo(hostname, None, socket.AF_INET6)[0][4][0]
except socket.gaierror:
    ipv6_address = "NotFound"

def generate_data_dict(app_name, request):
    return {
        'app': app_name,
        'hostname': os.getenv('HOST_HOSTNAME', hostname),
        'server-ipv4': os.getenv('HOST_IPV4', ipv4_address),
        'server-ipv6': os.getenv('HOST_IPV6', ipv6_address),
        'remote-addr': request.client.host,
        'headers': dict(request.headers)
    }

@router.get("/")
async def default(request: Request):
    return generate_data_dict('SERVER', request)

@router.get("/path1")
async def path1(request: Request):
    return generate_data_dict('SERVER-PATH1', request)

@router.get("/path2")
async def path2(request: Request):
    return generate_data_dict('SERVER-PATH2', request)

@router.get("/healthz")
async def healthz(request: Request):
    # Example of adding specific logic for a particular endpoint if needed
    # allowed_hosts = ["healthz.az.corp"]
    # if request.client.host not in allowed_hosts:
    #     raise HTTPException(status_code=403, detail="Access denied")
    return "OK"
