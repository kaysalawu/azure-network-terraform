import os
import socket
from fastapi import APIRouter, Request, HTTPException

router = APIRouter()

hostname = socket.gethostname()
address = socket.gethostbyname(hostname)

@router.get("/")
async def default(request: Request):
    data_dict = {
        'app': 'Web-Home',
        'hostname': os.getenv('HOST_HOSTNAME', hostname),
        'local-ip': os.getenv('HOST_IP', address),
        'remote-ip': request.client.host,
        'headers': dict(request.headers)
    }
    return data_dict

@router.get("/path1")
async def path1(request: Request):
    data_dict = {
        'app': 'Web-Path1',
        'hostname': os.getenv('HOST_HOSTNAME', hostname),
        'local-ip': os.getenv('HOST_IP', address),
        'remote-ip': request.client.host,
        'headers': dict(request.headers)
    }
    return data_dict

@router.get("/path2")
async def path2(request: Request):
    data_dict = {
        'app': 'Web-Path2',
        'hostname': os.getenv('HOST_HOSTNAME', hostname),
        'local-ip': os.getenv('HOST_IP', address),
        'remote-ip': request.client.host,
        'headers': dict(request.headers)
    }
    return data_dict

@router.get("/healthz")
async def healthz(request: Request):
    # allowed_hosts = ["healthz.az.corp"]
    # if request.client.host not in allowed_hosts:
    #     raise HTTPException(status_code=403, detail="Access denied")
    return "OK"
