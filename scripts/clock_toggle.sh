#!/bin/bash

STATE_FILE="/tmp/waybar_clock_alt"

if [[ -f "$STATE_FILE" ]]; then
    rm "$STATE_FILE"
else
    touch "$STATE_FILE"
fi
