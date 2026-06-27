#!/bin/bash
if [ -z "$1" ]; then
  echo "Usage: aerospace_windows.sh <focus|close>"
  exit 1
fi
cmd=$1

ws=$(aerospace list-workspaces --focused)
sel=$(aerospace list-windows --workspace $ws --format '%{window-id}│%{app-name} — %{window-title}' | choose)
[ -n "$sel" ] && aerospace $cmd --window-id "${sel%%│*}"
