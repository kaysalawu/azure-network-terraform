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
