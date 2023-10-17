#!/bin/bash

lsof -ti:1234 | xargs kill -9

# Find and kill the process listening on port 6666
#PID=$(lsof -t -i :1234)
##if [ -n "$PID" ]; then
#  kill "$PID"
#  echo "Killed process with PID $PID"
#else
#  echo "No process found listening on port 1234"
#fi
