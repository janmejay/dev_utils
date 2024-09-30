#!/usr/bin/env bash
set -e
core=/tmp/core
d=/var/lib/systemd/coredump/
ls -tr $d | head -1 | xargs -I% zstdcat $d%  > $core
echo "Dumped to $core"

if [ "x$1" == 'xkill' ]; then
    sudo find $d -type f -delete
fi
