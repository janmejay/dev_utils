#!/bin/bash
sel=$(aerospace list-windows --all \
        --format '%{window-id}│%{app-name} — %{window-title}' \
      | choose)
[ -n "$sel" ] && aerospace focus --window-id "${sel%%│*}"
