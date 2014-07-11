#!/usr/bin/env bash

# set variables
PORT=8081
PIDFILE="http.pid"

# Get the PID from PIDFILE if we don't have one yet.
if [[ -z "${PID}" && -e ${PIDFILE} ]]; then
  PID=$(cat ${PIDFILE});
fi
 
start() {
    if [[ -z "${PID}" ]]; then
        nohup python -m SimpleHTTPServer $PORT > http.log 2>&1 &
        echo $! > http.pid
    else
        echo "http server is already running (PID: ${PID})"
    fi
}

stop() {
  if [[ -z "${PID}" ]]; then
    echo "http server is not running (missing PID)."
  else
      kill ${PID}
      rm ${PIDFILE}
      echo "stopped http server (PID: ${PID})."
  fi
}

# Run the target passed as the first arg on the command line
# If no first arg, run server
if [ $# -gt 1 ]; then exit; fi
if [ $# = 1 ]; then $1; else start; fi
