from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class PingIn(BaseModel):
    message: str

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/ping")
def ping(payload: PingIn):
    return {"reply": f"pong: {payload.message}"}