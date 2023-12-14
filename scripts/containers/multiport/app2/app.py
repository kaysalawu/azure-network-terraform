import socket
from flask import Flask, request
app = Flask(__name__)

@app.route("/")
def default():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'APP2'
    data_dict['hostname'] = hostname
    data_dict['local-ip'] = address
    data_dict['remote-ip'] = request.remote_addr
    data_dict['headers'] = dict(request.headers)
    return data_dict

@app.route("/path1")
def path1():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'APP2-PATH1'
    data_dict['hostname'] = hostname
    data_dict['local-ip'] = address
    data_dict['remote-ip'] = request.remote_addr
    data_dict['headers'] = dict(request.headers)
    return data_dict

@app.route("/path2")
def path2():
    hostname = socket.gethostname()
    address = socket.gethostbyname(hostname)
    data_dict = {}
    data_dict['app'] = 'APP2-PATH2'
    data_dict['hostname'] = hostname
    data_dict['local-ip'] = address
    data_dict['remote-ip'] = request.remote_addr
    data_dict['headers'] = dict(request.headers)
    return data_dict

if __name__ == "__main__":
    app.run(host= '0.0.0.0', port=8081, debug = True)
EOF
