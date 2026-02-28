#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAS_SESSION="DALI_session"
WEB_SESSION="WEB_MVP"
WEB_TMUX_SOCKET="${WEB_TMUX_SOCKET:-webmvp}"

tmux_web() {
  tmux -L "$WEB_TMUX_SOCKET" "$@"
}

echo "Stopping web session: $WEB_SESSION"
tmux_web kill-session -t "$WEB_SESSION" 2>/dev/null || true
tmux kill-session -t "$WEB_SESSION" 2>/dev/null || true

echo "Stopping MAS using stop script..."
if [[ -x "$ROOT_DIR/stopmas.sh" ]]; then
  (
    cd "$ROOT_DIR"
    ./stopmas.sh "$MAS_SESSION" >/dev/null 2>&1 || true
  )
else
  tmux kill-session -t "$MAS_SESSION" 2>/dev/null || true
  pkill -9 -f active_server_wi.pl 2>/dev/null || true
  pkill -9 -x sicstus 2>/dev/null || true
fi

echo "Cleaning fallback processes..."
pkill -f "python3 -m http.server 5173" 2>/dev/null || true
pkill -f "uvicorn app.main:app --host 0.0.0.0 --port 8080" 2>/dev/null || true

echo "Done."
echo "- Stopped tmux session: $WEB_SESSION (if present)"
echo "- Stopped MAS session: $MAS_SESSION (if present)"
