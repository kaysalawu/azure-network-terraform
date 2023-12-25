import os
import socket
from flask import Flask, request

app = Flask(__name__)

hostname = socket.gethostname()
address = socket.gethostbyname(hostname)

@app.route("/")
def default():
    data_dict = {
        'app': 'APP2',
        'hostname': os.getenv('HOST_HOSTNAME', hostname),
        'local-ip': os.getenv('HOST_IP', address),
        'remote-ip': request.remote_addr,
        'headers': dict(request.headers)
    }
    return data_dict

@app.route("/path1")
def path1():
    data_dict = {
        'app': 'APP2-PATH1',
        'hostname': os.getenv('HOST_HOSTNAME', hostname),
        'local-ip': os.getenv('HOST_IP', address),
        'remote-ip': request.remote_addr,
        'headers': dict(request.headers)
    }
    return data_dict

@app.route("/path2")
def path2():
    data_dict = {
        'app': 'APP2-PATH2',
        'hostname': os.getenv('HOST_HOSTNAME', hostname),
        'local-ip': os.getenv('HOST_IP', address),
        'remote-ip': request.remote_addr,
        'headers': dict(request.headers)
    }
    return data_dict

@app.route("/healthz")
def healthz():
    return "OK"

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=${APP2_PORT}, debug=True)
