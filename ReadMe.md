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

