# Web MVP (Phase 1)

This folder contains the first implementation increment for web integration.

- Backend control plane API: `web_mvp/backend`
- Frontend dashboard: `web_mvp/frontend`

## Quick Start

### One command (MAS + backend + frontend)
From project root:
```bash
cd /home/studente/Simple
./run_all.sh
```

Stop everything:
```bash
cd /home/studente/Simple
./stop_all.sh
```

Deep restart (full cleanup + relaunch):
```bash
cd /home/studente/Simple
./deep_restart.sh
```

This starts:
- MAS in tmux session `DALI_session`
- Backend + frontend in tmux session `WEB_MVP`
- Dashboard auto-open (when `xdg-open` is available)
- Frontend auto-detects API host and auto-connects WebSocket

Optional flags:
- `START_MAS=0 ./run_all.sh` (start only web side)
- `AUTO_ATTACH_WEB=1 ./run_all.sh` (auto-attach to `WEB_MVP` session)
- `AUTO_OPEN_DASHBOARD=0 ./run_all.sh` (disable browser auto-open)

1. Start backend API:
```bash
cd web_mvp/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
```

2. Start frontend:
```bash
cd ../frontend
python3 -m http.server 5173
```

3. Open dashboard:
- `http://localhost:5173`
