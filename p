#!/usr/bin/env bash
ps waux | grep -F $1 | grep -v grep | grep -v 'bin/p '