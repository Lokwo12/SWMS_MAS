# MAS Web MVP Backend

Phase-1 backend control plane for the SICStus + DALI MAS.

## Features
- REST control endpoints
  - `POST /api/v1/system/start`
  - `POST /api/v1/system/stop`
  - `POST /api/v1/system/restart`
  - `POST /api/v1/system/healthcheck`
  - `GET  /api/v1/system/status`
- WebSocket endpoint
  - `GET /ws/events` (heartbeat + parsed logger lifecycle events)
- Command allowlist execution (no arbitrary shell commands)

## Run
```bash
cd web_mvp/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

## Notes
- Commands execute in `/home/studente/Simple`.
- This MVP intentionally wraps existing scripts without changing MAS logic.
- Event stream source: tmux `logger` pane lines are parsed into normalized JSON events.
