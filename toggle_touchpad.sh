#!/bin/bash
prop='Device Enabled'
dev_id=$(xinput list | grep -iP '(touchpad|Synaptics)' | grep -Po 'id=\d+' | grep -Po '\d+')

on=$(xinput list-props $dev_id | grep -F "$prop" | awk '{print $NF}')
if [ "x$on" == 'x0' ]; then
    xinput set-prop $dev_id "$prop" 1
else
    xinput set-prop $dev_id "$prop" 0
fi
