#!/bin/bash

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  # Check if gpu-screen-recorder has an output file open (recording vs selecting)
  pid=$(pgrep -f "^gpu-screen-recorder")
  if lsof -p "$pid" 2>/dev/null | grep -q "\.mp4"; then
    echo '{"text": "󰻂", "tooltip": "Stop recording", "class": "active"}'
  else
    echo '{"text": "󰻂", "tooltip": "Selecting...", "class": "selecting"}'
  fi
else
  echo '{"text": "󰻂", "tooltip": "Start recording", "class": "ready"}'
fi
