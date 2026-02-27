#!/bin/bash
set -e
shopt -s nullglob

clear

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- USER CONFIG ---
SICSTUS_HOME=/usr/local/sicstus4.6.0
DALI_HOME="${DALI_HOME:-$SCRIPT_DIR/src}"
PROLOG="$SICSTUS_HOME/bin/sicstus"
BUILD_HOME=build
INSTANCES_HOME=mas/instances
TYPES_HOME=mas/types
CONF_DIR=conf
WAIT="sleep 8"
LINDA_PORT=3010

# --- ENVIRONMENT CHECK ---
if ! command -v tmux &> /dev/null; then
    echo "Error: tmux is required."
    exit 1
fi

if [[ ! -x "$PROLOG" ]]; then
    echo "Error: SICStus Prolog not found at $PROLOG"
    exit 1
fi

# --- CLEANUP ---
echo "Stopping existing agents..."
killall sicstus 2>/dev/null || true
tmux kill-session -t DALI_session 2>/dev/null || true
pkill -9 -f active_server_wi.pl 2>/dev/null || true
pkill -9 -x sicstus 2>/dev/null || true
if command -v fuser &> /dev/null; then
    fuser -k -9 ${LINDA_PORT}/tcp 2>/dev/null || true
fi

echo "Cleaning environment..."
rm -rf tmp/* tmp/.[!.]* tmp/..?* \
    build/* build/.[!.]* build/..?* \
    work/* work/.[!.]* work/..?* \
    conf/mas/* conf/mas/.[!.]* conf/mas/..?*
mkdir -p tmp build work conf/mas

# --- SELECT FREE LINDA PORT ---
while ss -ltnH "sport = :${LINDA_PORT}" 2>/dev/null | grep -q .; do
    LINDA_PORT=$((LINDA_PORT + 1))
done
echo "Using LINDA port: ${LINDA_PORT}"

# --- BUILD AGENTS ---
echo "Building agent instances..."
for instance_path in $INSTANCES_HOME/*.txt; do
    instance_filename=$(basename "$instance_path")          # e.g., smart_bin.txt
    agent_name="${instance_filename%.txt}"                  # bare name
    agent_type=$(tr -d '\r' < "$instance_path")
    type_file="$TYPES_HOME/$agent_type.txt"

    if [[ -f "$type_file" ]]; then
        echo "Creating agent $agent_name (Type: $agent_type)"
        cat "$type_file" > "$BUILD_HOME/$agent_name.txt"
    else
        echo "Warning: Type file $type_file not found for $agent_name"
    fi
done

# Copy built agents to work folder
files=($BUILD_HOME/*.txt)
if [ ${#files[@]} -gt 0 ]; then
    cp "${files[@]}" work/
    cp "${files[@]}" tmp/
fi

# --- START LINDA SERVER ---
echo "Starting LINDA Server..."
server_ready=0
for _ in $(seq 1 10); do
    srvcmd="$PROLOG --noinfo -l $DALI_HOME/active_server_wi.pl --goal \"go(${LINDA_PORT},'server.txt').\""
    tmux new-session -d -s DALI_session -n "DALI_MAS" "$srvcmd"

    echo "Waiting for LINDA Server on port ${LINDA_PORT}..."
    $WAIT

    if tmux capture-pane -pt DALI_session.0 -S -80 | grep -Eq "SPIO_E_NET_ADDRINUSE|goal failed"; then
        tmux kill-session -t DALI_session 2>/dev/null || true
        LINDA_PORT=$((LINDA_PORT + 1))
        continue
    fi

    server_ready=1
    break
done

if [ "$server_ready" -ne 1 ]; then
    echo "Error: LINDA Server failed to start correctly after multiple ports."
    exit 1
fi

# Keep endpoint file consistent for runtimes resolving paths from src/
cp -f server.txt src/server.txt

# --- LAUNCH USER AGENT ---
echo "Launching User Agent..."
tmux split-window -v -t DALI_session "$PROLOG --noinfo -l $DALI_HOME/active_user_wi.pl"

# --- LAUNCH ALL MAS AGENTS ---
for agent_file in $BUILD_HOME/*.txt; do
    agent_name=$(basename "$agent_file" .txt)
    echo "Launching agent: $agent_name"

    # Generate proper config (conf/mas/agent_name.txt)
    $CONF_DIR/makeconf.sh "$agent_name" "$DALI_HOME"

    # Launch agent with exact bare name
    tmux split-window -v -t DALI_session "$CONF_DIR/startagent.sh $agent_name $PROLOG $DALI_HOME"

    tmux select-layout -t DALI_session tiled
    sleep 1
done

echo "All agents launched. Attaching tmux..."
tmux select-layout -t DALI_session tiled
tmux attach -t DALI_session