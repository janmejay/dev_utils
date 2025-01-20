#!/usr/bin/env bash

prop='Device Enabled'

dev_ids=$(
    xinput list | \
    grep -iP '(touchpad|Synaptics|Generic Mouse|ELAN|SNSL|TrackPoint)' | \
    grep -Po 'id=\d+' | \
    grep -Po '\d+' | \
    sort -nk1 | \
    xargs echo)

function is_on {
    on=$(xinput list-props $1 | grep -F "$prop" | awk '{print $NF}')
    if [ "x$on" == 'x0' ]; then
        echo "off"
    else
        echo "on"
    fi
}

dev_1=$(echo $dev_ids | awk '{print $1}')
on=$(is_on $dev_1)

for dev_id in $dev_ids; do
    if [ "x$on" == 'xon' ]; then
        xinput set-prop $dev_id "$prop" 0
        hide_mouse_ptr &
    else
        xinput set-prop $dev_id "$prop" 1
        pkill hide_mouse_ptr
    fi
done
