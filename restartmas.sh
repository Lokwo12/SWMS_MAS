#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_NAME="${1:-DALI_session}"

cd "$SCRIPT_DIR"

echo "Restarting MAS (session: ${SESSION_NAME})..."

if [[ -x "$SCRIPT_DIR/stopmas.sh" ]]; then
  "$SCRIPT_DIR/stopmas.sh" "$SESSION_NAME"
else
  echo "Warning: stopmas.sh not found or not executable, attempting fallback stop"
  killall -q sicstus 2>/dev/null || true
  tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
fi

sleep 1

if [[ -x "$SCRIPT_DIR/startmas.sh" ]]; then
  exec "$SCRIPT_DIR/startmas.sh"
else
  echo "Error: startmas.sh not found or not executable"
  exit 1
fi
