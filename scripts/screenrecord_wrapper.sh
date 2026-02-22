#!/bin/bash

# Wrapper around omarchy-cmd-screenrecord that prompts for a filename after stopping.

MAX_CHARS=50

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  # Recording is active — find the file before stopping
  pid=$(pgrep -f "^gpu-screen-recorder")
  recorded_file=$(lsof -p "$pid" 2>/dev/null | grep '\.mp4' | awk '{print $NF}')

  # Stop the recording
  omarchy-cmd-screenrecord

  # Prompt for rename
  if [[ -n "$recorded_file" && -f "$recorded_file" ]]; then
    new_name=$(zenity --entry \
      --title="Save Screen Recording" \
      --text="Enter a file name (max ${MAX_CHARS} characters):" \
      --width=400 \
      2>/dev/null)

    if [[ $? -eq 0 && -n "$new_name" ]]; then
      new_name="${new_name:0:$MAX_CHARS}"
      new_name=$(echo "$new_name" | sed 's/[\/]//g; s/^[[:space:]]*//; s/[[:space:]]*$//')

      # Extract timestamp from original filename (e.g. 2025-02-22_14-30-00)
      timestamp=$(basename "$recorded_file" .mp4 | sed 's/^screenrecording-//')
      new_path="$OUTPUT_DIR/${new_name}_${timestamp}.mp4"

      # Avoid overwriting existing files
      if [[ -f "$new_path" ]]; then
        new_path="$OUTPUT_DIR/${new_name}_${timestamp}_$(date +'%s').mp4"
      fi

      mv "$recorded_file" "$new_path"
      notify-send "Recording saved" "$(basename "$new_path")" -t 2000
    fi
  fi
else
  # Not recording — pass through to start
  omarchy-cmd-screenrecord "$@"
fi
