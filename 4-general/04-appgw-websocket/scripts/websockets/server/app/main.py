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
