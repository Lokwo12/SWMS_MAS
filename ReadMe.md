

# Installation (for visitors)

This project runs a SICStus Prolog + DALI multi-agent simulation of smart waste collection.

### 1) Prerequisites

- Linux environment
- [tmux](https://github.com/tmux/tmux/wiki/Installing)
- SICStus Prolog 4.6.x

By default, `startmas.sh` expects SICStus at:

`/usr/local/sicstus4.6.0/bin/sicstus`

If SICStus is installed elsewhere, update `SICSTUS_HOME` in `startmas.sh`.

### 2) Open the project

From a terminal:

`cd /path/to/Simple`

### 3) Make scripts executable (first time only)

`chmod +x startmas.sh stopmas.sh restartmas.sh healthcheck.sh`

### 4) Start the multi-agent system

`./startmas.sh`

What this does automatically:

- stops old SICStus/tmux processes,
- rebuilds agent instances,
- starts the Linda server,
- launches all agents in a tiled tmux session,
- runs an automatic health check.

### 5) Verify installation/runtime

Run:

`./healthcheck.sh`

Expected result:

- all expected panes are present (`LINDA_SERVER`, `control_center`, `logger`, `smart_bin1..3`, `truck1..3`),
- lifecycle signals are detected in logger output.

### 6) Stop the system

`./stopmas.sh`

### 7) Common troubleshooting

- **`tmux` not found**: install tmux and rerun `./startmas.sh`.
- **SICStus not found**: verify installation path or adjust `SICSTUS_HOME` in `startmas.sh`.
- **Port conflict**: startup script auto-increments Linda port if busy.
- **Detached execution**: run with `NO_ATTACH=1 ./startmas.sh` to start in background without attaching tmux.

## Operations

Run from the project root:

- Start MAS: `./startmas.sh`
- Stop MAS: `./stopmas.sh`
- Restart MAS: `./restartmas.sh`
- Health check: `./healthcheck.sh`

Optional environment variables:

- Disable automatic startup health check: `AUTO_HEALTHCHECK=0 ./startmas.sh`
- Change health check wait time (seconds): `HEALTHCHECK_WAIT=30 ./startmas.sh`
- Run health check with custom wait: `WAIT_SECONDS=30 ./healthcheck.sh`


## Web Base Launch (MVP Dashboard)

The project includes a web control/monitoring MVP under `web_mvp/`.

### Option A: one-command launch (recommended)

From project root:

- Start MAS + backend + frontend: `./run_all.sh`
- Stop all services: `./stop_all.sh`
- Full cleanup + relaunch: `./deep_restart.sh`

This starts:

- MAS in tmux session `DALI_session`
- Web backend + frontend in tmux session `WEB_MVP`
- Dashboard at `http://localhost:5173`

Useful flags:

- `START_MAS=0 ./run_all.sh` (launch web side only)
- `AUTO_ATTACH_WEB=1 ./run_all.sh` (auto-attach `WEB_MVP` session)
- `AUTO_OPEN_DASHBOARD=0 ./run_all.sh` (disable browser auto-open)

### Option B: manual launch

1) Backend API:

`cd web_mvp/backend`

`python3 -m venv .venv`

`source .venv/bin/activate`

`pip install -r requirements.txt`

`uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload`

2) Frontend dashboard (new terminal):

`cd web_mvp/frontend`

`python3 -m http.server 5173`

3) Open:

`http://localhost:5173`
