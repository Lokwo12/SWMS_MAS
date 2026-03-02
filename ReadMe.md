
# SMART WASTE MANAGEMENT SYSTEM (SWMS_MAS)

Is a multi-agent framework for modeling and analyzing intelligent urban waste-collection operations. The system formalizes waste management as a distributed coordination problem, where autonomous agents (smart bins, collection trucks, a control center, and a logger) interact through structured communication protocols to detect overflow conditions, negotiate service allocation, execute collection tasks, and restore normal operating states. By combining autonomous decision-making, retry and timeout policies, and event-level observability, SWMS_MAS provides a reproducible environment for studying robustness, scalability, and operational efficiency in cyber-physical municipal services. The platform is designed both as a research testbed for Multi-Agent Systems (MAS) methodologies and as a practical prototype for data-driven, resilient smart-city waste management.


# System Objective

- Build an autonomous waste-collection MAS where smart bins self-report fullness, a control center dispatches trucks, trucks negotiate availability, collection is completed, and bins are reset.
- Preserve autonomous DALI/SICStus behavior while enabling operational control and observability through a web wrapper (control API, realtime stream, audit, health).

## Full System Architecture (GAIA-aligned)

- **Environment layer:** SICStus runtime, Linda tuple-space server, tmux-based multi-agent session, shell lifecycle scripts.
- **Agent society layer (current MAS):** 8 agents in one organization: `1 Control Center,`` 1 Logger, 3 Smart Bins, 3 Trucks.`
- **Coordination layer:** asynchronous inform-based messaging; Control Center maintains dispatch state, retries, cooldowns, and inflight watchdog.
- **Observability layer (current):** logger receives and prints filtered lifecycle messages; health script validates process/session/panes and lifecycle signals.
- **Web integration layer (target wrapper):** Dashboard + Backend Orchestrator + WebSocket Gateway + Event Normalizer + Persistence/Audit, non-invasive to MAS core logic.

## Agent role and Virtual Organization.
| roles | agent name | responsibility |
|---|---|---|
| Coordinator | control_center | Receives full-bin alerts, selects trucks, manages retries/timeouts, and sends clear/reset commands after collection. |
| Collector | truck1, truck2, truck3 | Accepts/refuses collection requests, performs collection lifecycle, reports agree/refuse/collected to control center. |
| Sensor/Producer | smart_bin1, smart_bin2, smart_bin3 | Simulates fill-level progression, emits full alerts at 100%, and resets to 0 when cleared. |
| Observer/Telemetry | logger | Receives domain events from all agents, prints deduplicated flow logs, and sends heartbeat/alive signal. |

### Roles and Interactions

| from | to | message/event |
|---|---|---|
| smart_bin1, smart_bin2, smart_bin3 | logger | `inform(status(BinID, Level), BinID)` |
| smart_bin1, smart_bin2, smart_bin3 | control_center | `inform(full(BinID), BinID)` |
| control_center | truck1, truck2, truck3 | `inform(collect(BinID), control_center)` |
| truck1, truck2, truck3 | control_center | `inform(agree(TruckID, BinID), TruckID)` |
| truck1, truck2, truck3 | control_center | `inform(refuse(TruckID, BinID), TruckID)` |
| truck1, truck2, truck3 | control_center | `inform(collected(TruckID, BinID), TruckID)` |
| truck1, truck2, truck3 | logger | `inform(accepted(TruckID, BinID), TruckID)` |
| truck1, truck2, truck3 | logger | `inform(refused(TruckID, BinID), TruckID)` |
| truck1, truck2, truck3 | logger | `inform(working(TruckID, BinID), TruckID)` |
| truck1, truck2, truck3 | logger | `inform(ready(TruckID), TruckID)` |
| control_center | logger | `inform(full_received(BinID), control_center)` |
| control_center | logger | `inform(requesting(TruckID, BinID, Mode), control_center)` |
| control_center | logger | `inform(assigned(TruckID, BinID), control_center)` |
| control_center | logger | `inform(refused(TruckID, BinID), control_center)` |
| control_center | logger | `inform(completed(TruckID, BinID), control_center)` / `inform(completed(timeout, BinID), control_center)` |
| control_center | smart_bin1, smart_bin2, smart_bin3 | `inform(cleared, control_center)` |
| smart_bin1, smart_bin2, smart_bin3 | logger | `inform(reset(BinID), BinID)` |
| logger | control_center | `inform(alive(LoggerID), LoggerID)` |

### Action Table

| agent | action | description |
|---|---|---|
| control_center | `process_full_events/1` | Consumes full-bin alerts, marks bin awaiting, initializes dispatch state, and logs `full_received`. |
| control_center | `dispatch_request/1` | Selects candidate truck (with busy/tried filtering), marks inflight, and sends `collect(BinID)`. |
| control_center | `process_truck_events/1` | Handles truck `agree/refuse/collected` outcomes and updates assignment, retry, and completion state. |
| control_center | `tick_inflight_watchdog/1` | Monitors inflight timeout, schedules retry, or forces timeout completion fallback after max retries. |
| control_center | `process_waiting_bins/1` | Triggers dispatch for awaiting bins when dispatch/retry countdowns expire. |
| truck1, truck2, truck3 | `process_collect_orders/1` | Reads incoming collect requests and enqueues decision countdown. |
| truck1, truck2, truck3 | `process_pending_decisions/1` | Applies acceptance probability and emits `agree`/`refuse` plus logger telemetry. |
| truck1, truck2, truck3 | `start_collectionI/1` | Emits `working` event when collection start delay reaches zero. |
| truck1, truck2, truck3 | `complete_collectionI/1` | Emits `collected` to control center and `ready` to logger when collection completes. |
| truck1, truck2, truck3 | `tick_busy/1` | Decrements truck busy cycles controlling availability state. |
| smart_bin1, smart_bin2, smart_bin3 | `auto_fillI/1` | Advances fill level on schedule, emits status, and triggers full alert at 100%. |
| smart_bin1, smart_bin2, smart_bin3 | `handle_cleared_message/1` | Resets fill level and cooldown after `cleared` command. |
| smart_bin1, smart_bin2, smart_bin3 | `tick_reset_cooldown/1` | Advances post-reset pause before filling resumes. |
| logger | `process_logs/1` | Consumes incoming informs, filters noise, deduplicates, and prints log flow lines. |
| logger | `heartbeatI/1` | Sends periodic alive heartbeat to control center. |




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

`cd /path/to/SWMS_MAS`

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
