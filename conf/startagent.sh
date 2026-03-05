#!/bin/bash
# $1 = agent name (bare, e.g., smart_bin)
# $2 = SICStus path
# $3 = DALI_HOME path

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Normalize agent name (accepts truck1 or truck1.txt)
AGENT_NAME="${1%.txt}"
AGENT_FILE="$AGENT_NAME.txt"
AGENT_CONF="$ROOT_DIR/conf/mas/$AGENT_FILE"

echo "Launching agent instance: $AGENT_FILE"

# Launch agent
$2 --noinfo -l "$3/active_dali_wi.pl" --goal "start0('$AGENT_CONF')."