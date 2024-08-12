#!/usr/bin/env bash
prop='Device Enabled'
dev_id=$(xinput list | grep -iP '(touchpad|Synaptics|Generic Mouse)' | grep -Po 'id=\d+' | grep -Po '\d+')

on=$(xinput list-props $dev_id | grep -F "$prop" | awk '{print $NF}')
if [ "x$on" == 'x0' ]; then
    xinput set-prop $dev_id "$prop" 1
    pkill hide_mouse_ptr
else
    xinput set-prop $dev_id "$prop" 0
    hide_mouse_ptr &
fi
