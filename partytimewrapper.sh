#!/usr/bin/env bash

## This script launches at login, removes the host from specificed BB Groups.  
## It then waits running in the background, and upon GUI logout adds the host to specified BB Groups.

partytime_add() {
  nohup sudo -u partytime /opt/instinctual/partytime/partytime.sh --add >/dev/null 2>&1 &
}

sudo -u partytime /opt/instinctual/partytime/partytime.sh --remove 2>&1 &

trap partytime_add INT TERM EXIT
sleep infinity