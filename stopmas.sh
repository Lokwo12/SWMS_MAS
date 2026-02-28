#!/bin/bash
set -euo pipefail

SESSION_NAME="${1:-DALI_session}"

echo "Stopping MAS session: ${SESSION_NAME}"

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Session '$SESSION_NAME' detected (kept alive for control continuity)"
else
  echo "Session '$SESSION_NAME' not found (already stopped)"
fi

killall -q sicstus 2>/dev/null || true
pkill -9 -f active_server_wi.pl 2>/dev/null || true
pkill -9 -x sicstus 2>/dev/null || true

echo "MAS processes stopped"
