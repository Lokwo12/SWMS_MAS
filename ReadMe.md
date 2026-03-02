

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

`cd /path/to/Simple`

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




# DALI Advanced Examples

In this folder the example show how to define 
classes of agents and agent instances, based on 
sources files.

You define first an agent class in the folder `mas/types'`
then you can define as many instances you want,
only limited by the resources of your machine,
in the folder `mas/instances`

## MAS startup

Be sure to have the terminal multiplexer
[tmux](https://github.com/tmux/tmux/wiki/Installing) 
installed in the system.

Then use the command that should open a multiple terminal 
console in which every single agent shows its messages.

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

### TMUX shortcuts

* ...
* ...

# Other advanced examples

## Mobile Robotics

* [TurtleBot2 MAS Project](https://github.com/valent0ne/turtlebot2-mas) 
* (more to come..)

