#!/bin/bash

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  # Check if gpu-screen-recorder has an output file open (recording vs selecting)
  pid=$(pgrep -f "^gpu-screen-recorder")
  mp4_file=$(lsof -p "$pid" 2>/dev/null | grep '\.mp4' | awk '{print $NF}')
  if [[ -n "$mp4_file" ]]; then
    start=$(stat -c %W "$mp4_file")
    elapsed=$(( $(date +%s) - start ))
    mins=$(( elapsed / 60 ))
    secs=$(( elapsed % 60 ))
    duration=$(printf "%d:%02d" "$mins" "$secs")
    echo "{\"text\": \"󰻂 ${duration}\", \"tooltip\": \"Stop recording\", \"class\": \"active\"}"
  else
    echo '{"text": "󰻂", "tooltip": "Selecting...", "class": "selecting"}'
  fi
else
  echo '{"text": "󰻂", "tooltip": "Start recording", "class": "ready"}'
fi
