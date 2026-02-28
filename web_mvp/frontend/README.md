# MAS Web MVP Frontend

Browser dashboard for controlling and monitoring the MAS backend API.

## Features
- Start / Stop / Restart / Healthcheck buttons
- Live system status polling
- Realtime WebSocket event console
- Configurable API base URL from the UI

## Run (static)
```bash
cd web_mvp/frontend
python3 -m http.server 5173
```
Then open `http://localhost:5173`.

## Backend prerequisite
Run backend first:
```bash
cd ../backend
source .venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```
