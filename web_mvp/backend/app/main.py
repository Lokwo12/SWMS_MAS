from datetime import datetime, UTC
import asyncio
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import router as system_router
from app.services.event_stream import EventStreamService


app = FastAPI(title="MAS Control API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(system_router)

stream_service = EventStreamService()


@app.on_event("startup")
async def startup_event_stream() -> None:
    asyncio.create_task(stream_service.run_forever())


@app.get("/")
def root() -> dict[str, str]:
    return {"service": "mas-control-api", "status": "ok"}


@app.websocket("/ws/events")
async def ws_events(websocket: WebSocket) -> None:
    await stream_service.register(websocket)
    try:
        while True:
            await websocket.send_text(
                f'{{"type":"heartbeat","source":"mas-control-api","ts":"{datetime.now(UTC).isoformat()}"}}'
            )
            await asyncio.sleep(5)
    except Exception:
        await stream_service.unregister(websocket)
        await websocket.close()
