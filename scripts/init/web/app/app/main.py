from fastapi import FastAPI, Request, Response, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from _app import router as app_router
import json
import ssl
import uvicorn

class PrettyJSONResponse(Response):
    media_type = "application/json"

    def render(self, content: any) -> bytes:
        return json.dumps(content, indent=2).encode('utf-8')

app = FastAPI(default_response_class=PrettyJSONResponse)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Replace * with actual frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom middleware to add Access-Control-Allow-Origin header
@app.middleware("http")
async def add_cors_header(request, call_next):
    response = await call_next(request)
    response.headers["Access-Control-Allow-Origin"] = "*"
    return response

# Include the API router
app.include_router(app_router, tags=["Features"])

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=80
    )

