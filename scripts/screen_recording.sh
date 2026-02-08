#!/bin/bash

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  # Check if output file is being written (recording started)
  # Find screenrecording files modified in the last 5 seconds
  recent_file=$(find "$OUTPUT_DIR" -name "screenrecording-*.mp4" -mmin -0.1 2>/dev/null | head -1)

  if [ -n "$recent_file" ]; then
    echo '{"text": "󰻂", "tooltip": "Stop recording", "class": "active"}'
  else
    echo '{"text": "󰻂", "tooltip": "Selecting...", "class": "selecting"}'
  fi
else
  echo '{"text": "󰻂", "tooltip": "Start recording", "class": "ready"}'
fi
