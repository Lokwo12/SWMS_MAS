#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/web_mvp/backend"
FRONTEND_DIR="$ROOT_DIR/web_mvp/frontend"
WEB_SESSION="WEB_MVP"
WEB_TMUX_SOCKET="${WEB_TMUX_SOCKET:-webmvp}"

START_MAS="${START_MAS:-1}"
AUTO_ATTACH_WEB="${AUTO_ATTACH_WEB:-0}"
AUTO_OPEN_DASHBOARD="${AUTO_OPEN_DASHBOARD:-1}"
DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:5173}"

open_dashboard_url() {
  local url="$1"

  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$url" >/dev/null 2>&1 && return 0
  fi

  if command -v wslview >/dev/null 2>&1; then
    wslview "$url" >/dev/null 2>&1 && return 0
  fi

  if command -v powershell.exe >/dev/null 2>&1; then
    powershell.exe -NoProfile -Command "Start-Process '$url'" >/dev/null 2>&1 && return 0
  fi

  if command -v cmd.exe >/dev/null 2>&1; then
    cmd.exe /C start "" "$url" >/dev/null 2>&1 && return 0
  fi

  return 1
}

if ! command -v tmux >/dev/null 2>&1; then
  echo "Error: tmux is required."
  exit 1
fi

tmux_web() {
  tmux -L "$WEB_TMUX_SOCKET" "$@"
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 is required."
  exit 1
fi

if [[ "$START_MAS" == "1" ]]; then
  echo "Starting MAS (background tmux mode)..."
  (
    cd "$ROOT_DIR"
    NO_ATTACH=1 AUTO_HEALTHCHECK=1 HEALTHCHECK_WAIT=10 ./startmas.sh
  )
else
  echo "Skipping MAS startup (START_MAS=$START_MAS)."
fi

if [[ ! -d "$BACKEND_DIR/.venv" ]]; then
  echo "Creating backend virtualenv..."
  python3 -m venv "$BACKEND_DIR/.venv"
fi

VENV_PY="$BACKEND_DIR/.venv/bin/python"

if [[ ! -x "$VENV_PY" ]]; then
  echo "Error: virtualenv python not found at $VENV_PY"
  exit 1
fi

if ! "$VENV_PY" -m pip --version >/dev/null 2>&1; then
  echo "Bootstrapping pip in backend virtualenv..."
  "$VENV_PY" -m ensurepip --upgrade >/dev/null
fi

echo "Ensuring backend dependencies are installed..."
"$VENV_PY" -m pip install -r "$BACKEND_DIR/requirements.txt" >/dev/null

echo "Restarting web session: $WEB_SESSION"
tmux_web kill-session -t "$WEB_SESSION" 2>/dev/null || true

tmux_web new-session -d -s "$WEB_SESSION" -n web
tmux_web split-window -v -t "$WEB_SESSION":0
tmux_web select-layout -t "$WEB_SESSION":0 tiled

tmux_web send-keys -t "$WEB_SESSION":0.0 "cd '$BACKEND_DIR' && .venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8080" C-m
tmux_web send-keys -t "$WEB_SESSION":0.1 "cd '$FRONTEND_DIR' && python3 -m http.server 5173" C-m

if [[ "$AUTO_ATTACH_WEB" == "1" ]]; then
  tmux_web set-option -t "$WEB_SESSION" -g pane-border-status top
  tmux_web set-option -t "$WEB_SESSION" -g pane-border-format '#{pane_title}'
  tmux_web select-pane -t "$WEB_SESSION":0.0 -T "WEB_BACKEND"
  tmux_web select-pane -t "$WEB_SESSION":0.1 -T "WEB_FRONTEND"
  echo "Attaching web session..."
  tmux_web attach -t "$WEB_SESSION"
  exit 0
fi

echo ""
echo "All services launched."
echo "- MAS session: DALI_session"
echo "- Web session: $WEB_SESSION"
echo "- Dashboard: $DASHBOARD_URL"
echo "- API: http://localhost:8080/api/v1/system/status"
echo ""
echo "Optional: tmux -L $WEB_TMUX_SOCKET attach -t $WEB_SESSION"

if [[ "$AUTO_OPEN_DASHBOARD" == "1" ]]; then
  sleep 1
  if open_dashboard_url "$DASHBOARD_URL"; then
    echo "Opened dashboard in browser."
  else
    echo "Could not auto-open browser. Open manually: $DASHBOARD_URL"
  fi
fi
