#!/bin/bash
# $1 = agent name (bare, e.g., smart_bin)
# $2 = DALI_HOME path

set -e  # Stop on any error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Ensure conf/mas exists
mkdir -p "$ROOT_DIR/conf/mas"

# Normalize agent name (accepts truck1 or truck1.txt)
agent_name="${1%.txt}"

# Filename in conf/mas folder
agent_file="$agent_name.txt"
agent_base="$agent_name"

# Generate configuration
cat <<EOF > "$ROOT_DIR/conf/mas/$agent_file"
agent('$ROOT_DIR/tmp/$agent_base','$agent_name','no',italian,
      ['$ROOT_DIR/conf/communication'],
      ['$2/communication_fipa','$2/learning','$2/planasp'],
      'no',
      '$2/onto/dali_onto.txt',
      []).
EOF

echo "Created configuration for agent: $agent_name ($agent_file)"