#!/bin/bash

url=$(ps -ef | grep -F 'cockroach start' | grep -Po '/tmp/[^ ]*url' | xargs cat | grep .)
bin=$(ps -ef | grep -F 'cockroach start' | grep -Po '/tmp/[^ ]+ start' | awk '{print $1}')

exec $bin sql --url="$url" "$@"
