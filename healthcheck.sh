#!/bin/bash
set -euo pipefail

SESSION="${1:-}"
WAIT_SECONDS="${WAIT_SECONDS:-20}"

if [[ -z "$SESSION" ]]; then
  if tmux has-session -t DALI_session 2>/dev/null; then
    SESSION="DALI_session"
  elif tmux has-session -t MAS 2>/dev/null; then
    SESSION="MAS"
  else
    SESSION="DALI_session"
  fi
fi

echo "Health check session: ${SESSION}"

if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "FAIL: tmux session '$SESSION' not found"
  exit 1
fi

EXPECTED_TITLES=(
  "LINDA_SERVER"
  "control_center"
  "logger"
  "smart_bin1"
  "smart_bin2"
  "smart_bin3"
  "truck1"
  "truck2"
  "truck3"
)

pane_titles="$(tmux list-panes -t "$SESSION" -F '#{pane_title}')"

missing=0
for title in "${EXPECTED_TITLES[@]}"; do
  if ! printf '%s\n' "$pane_titles" | grep -Fxq "$title"; then
    echo "FAIL: missing pane title '$title'"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "OK: all expected panes are present"

echo "Waiting ${WAIT_SECONDS}s for activity..."
sleep "$WAIT_SECONDS"

logger_pane="$(tmux list-panes -t "$SESSION" -F '#{pane_id} #{pane_title}' | awk '$2=="logger" {print $1; exit}')"
if [[ -z "$logger_pane" ]]; then
  echo "FAIL: logger pane not found"
  exit 1
fi

logger_tail="$(tmux capture-pane -pt "$logger_pane" -S -200 || true)"
if printf '%s\n' "$logger_tail" | grep -Eiq 'full_received|assigned\(|completed\(|reset\('; then
  echo "OK: lifecycle flow signals detected in logger pane"
else
  echo "WARN: no lifecycle signals detected yet in logger pane"
fi

echo "Health check completed"
