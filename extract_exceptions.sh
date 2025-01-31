#!/usr/bin/env bash

log_file=$1

function die() {
    echo $*
    exit 100
}

if [ -f $log_file ]; then
    echo "Using log-file: ${log_file}"
else
    die "Couldn't find log-file: $log_file"
fi

cat $log_file | awk 'BEGIN {previous = ""} 
                     { current=$0; }
                     /^\tat/ {
