#!/bin/bash

export GO111MODULE=off

if [ -e /home/janmejay/.nix-profile/etc/profile.d/nix.sh ]; then . /home/janmejay/.nix-profile/etc/profile.d/nix.sh; fi

/usr/bin/emacs $*
