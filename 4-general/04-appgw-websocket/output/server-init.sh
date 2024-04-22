#cloud-config

package_update: true
package_upgrade: true
packages:
  - docker.io
  - docker-compose
  - npm

write_files:
  - path: /var/lib/azure/Dockerfile
    owner: root
    permissions: 0744
    content: |
      FROM python:3.12-alpine
      WORKDIR /app
      COPY . .
      RUN pip install --verbose --no-cache-dir -r requirements.txt
      EXPOSE 8080
      CMD ["python3", "main.py"]
      
  - path: /var/lib/azure/main.py
    owner: root
    permissions: 0744
    content: |
      import asyncio
      import websockets
      import json
      
      async def handler(websocket, path):
          # Receive a message from client
          message = await websocket.recv()
          print(f"Received message from client: {message}")
      
          # Send "busy" message to client
          busy_message = json.dumps({"success": "busy"})
          success_message = json.dumps({"success": "true"})
          await websocket.send(busy_message)
          print(busy_message, flush=True)
      
          # Wait for 10 seconds
          await asyncio.sleep(10)
      
          # Send JSON message {"success": true} to client
          await websocket.send(success_message)
          print(success_message, flush=True)
      
      print("\u23F3 Starting server on port 8080")
      start_server = websockets.serve(handler, "0.0.0.0", 8080)
      asyncio.get_event_loop().run_until_complete(start_server)
      print("\u2714 Server started")
      
      asyncio.get_event_loop().run_forever()
      print("\u23F3 Waiting for incoming messages...")
      
  - path: /var/lib/azure/requirements.txt
    owner: root
    permissions: 0744
    content: |
      websockets==11.0.3
      

runcmd:
  - systemctl enable docker
  - systemctl start docker
  - npm install -g wscat
  - cd /var/lib/azure
  - docker build -t server .
  - docker run -d -p 8080:8080 --name server server
  - docker run -d -p 80:80 --name nginx nginx
