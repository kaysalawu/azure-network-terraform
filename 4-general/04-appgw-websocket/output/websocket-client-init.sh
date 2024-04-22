#cloud-config

package_update: true
package_upgrade: true
packages:
  - docker.io
  - docker-compose
  - npm
  - python3-pip
  - python3-dev
  - python3-venv

write_files:
  - path: /var/lib/azure/Dockerfile
    owner: root
    permissions: 0744
    content: |
      FROM python:3.12-alpine
      WORKDIR /app
      COPY . .
      RUN pip install --verbose --no-cache-dir -r requirements.txt
      EXPOSE 80
      CMD ["python3", "main.py"]
      
  - path: /var/lib/azure/main.py
    owner: root
    permissions: 0744
    content: |
      import asyncio
      import websockets
      import json
      
      async def run_client():
          server = input("Enter target server's address (IP or DNS): ")
          uri = f"ws://{server}"
          async with websockets.connect(uri) as websocket:
              # Step 1: Send a message to server
              await websocket.send("Hello Server!")
              print("Sent message to server")
      
              # Step 3: Receive and print the "busy" message from the server
              busy_message = await websocket.recv()
              print(f"Received from server: {busy_message}")
      
              # Receive and print the success JSON message from the server
              success_message = await websocket.recv()
              success_data = json.loads(success_message)
              print(f"Received from server: {success_data}")
      
      asyncio.get_event_loop().run_until_complete(run_client())
      
  - path: /var/lib/azure/requirements.txt
    owner: root
    permissions: 0744
    content: |
      websocket-client==0.53.0
      

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - npm install -g wscat
