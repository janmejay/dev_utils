#!/usr/bin/env bash

if [ "x$1" == 'x' ]; then
    echo "Usage: $0 <executable>"
    exit 1
fi

intrp=$(patchelf --print-interpreter $(which patchelf))

patchelf --set-interpreter $intrp $1
