#!/bin/bash

STATE_FILE="/tmp/waybar_clock_alt"

if [[ -f "$STATE_FILE" ]]; then
    # Alt format: Day Mon wWW YYYY
    date "+%a %b w%V %Y"
else
    # Primary format: HH:MM DDth
    hour=$(date +%H)
    minute=$(date +%M)
    day=$(date +%-d)

    case "$day" in
        1|21|31) suffix="st" ;;
        2|22)    suffix="nd" ;;
        3|23)    suffix="rd" ;;
        *)       suffix="th" ;;
    esac

    echo "${hour}:${minute} ${day}${suffix}"
fi
