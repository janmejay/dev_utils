#!/bin/bash

iface=${1:-pj0}

sudo ip route del 13.249.0.0/16 dev pj0
