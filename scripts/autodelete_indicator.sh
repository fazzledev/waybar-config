#!/bin/bash

# Shows a trash icon with remaining time when auto-delete is scheduled.

deadline_file="/tmp/screenrecord-autodelete-deadline"

if ! systemctl --user is-active screenrecord-autodelete.timer &>/dev/null || [[ ! -f "$deadline_file" ]]; then
  echo '{"text": "", "tooltip": "", "class": "inactive"}'
  exit 0
fi

target=$(cat "$deadline_file")
now=$(date +%s)
remaining=$(( target - now ))

if [[ "$remaining" -gt 0 ]]; then
  mins=$(( remaining / 60 ))
  secs=$(( remaining % 60 ))
  echo "{\"text\": \" 󰩹 ${mins}:$(printf '%02d' $secs) \", \"tooltip\": \"Click to cancel auto-delete\", \"class\": \"active\"}"
else
  echo '{"text": "", "tooltip": "", "class": "inactive"}'
fi
