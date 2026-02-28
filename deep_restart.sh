#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DALI_SESSION="${DALI_SESSION:-DALI_session}"
WEB_SESSION="${WEB_SESSION:-WEB_MVP}"
LINDA_PORT_BASE="${LINDA_PORT_BASE:-3010}"

cd "$ROOT_DIR"

echo "[deep-restart] stopping all services..."
if [[ -x "$ROOT_DIR/stop_all.sh" ]]; then
  ./stop_all.sh
fi

echo "[deep-restart] killing lingering tmux sessions..."
tmux kill-session -t "$DALI_SESSION" 2>/dev/null || true
tmux kill-session -t "$WEB_SESSION" 2>/dev/null || true

echo "[deep-restart] killing lingering processes..."
pkill -9 -f active_server_wi.pl 2>/dev/null || true
pkill -9 -x sicstus 2>/dev/null || true
pkill -9 -f "python3 -m http.server 5173" 2>/dev/null || true
pkill -9 -f "uvicorn app.main:app --host 0.0.0.0 --port 8080" 2>/dev/null || true

echo "[deep-restart] freeing likely busy ports..."
if command -v fuser >/dev/null 2>&1; then
  fuser -k -9 ${LINDA_PORT_BASE}/tcp 2>/dev/null || true
  fuser -k -9 8080/tcp 2>/dev/null || true
  fuser -k -9 5173/tcp 2>/dev/null || true
fi

echo "[deep-restart] cleaning runtime folders..."
rm -rf tmp/* tmp/.[!.]* tmp/..?* \
       build/* build/.[!.]* build/..?* \
       work/* work/.[!.]* work/..?* \
       conf/mas/* conf/mas/.[!.]* conf/mas/..?* 2>/dev/null || true
mkdir -p tmp build work conf/mas

echo "[deep-restart] launching all services..."
./run_all.sh

echo "[deep-restart] done."
