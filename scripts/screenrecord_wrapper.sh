#!/bin/bash

# Wrapper around omarchy-cmd-screenrecord that prompts for a filename
# and post-processing options after stopping a recording.

MAX_CHARS=50

[[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
OUTPUT_DIR="${OMARCHY_SCREENRECORD_DIR:-${XDG_VIDEOS_DIR:-$HOME/Videos}}"

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  # Recording is active — find the file before stopping
  pid=$(pgrep -f "^gpu-screen-recorder")
  recorded_file=$(lsof -p "$pid" 2>/dev/null | grep '\.mp4' | awk '{print $NF}')

  # Stop the recording
  omarchy-cmd-screenrecord

  # Prompt for rename and post-processing
  if [[ -n "$recorded_file" && -f "$recorded_file" ]]; then
    result=$(yad --form \
      --title="Save Screen Recording" \
      --text="Max ${MAX_CHARS} characters" \
      --field="File name" "" \
      --field="Skip frames:CHK" TRUE \
      --field="Copy to clipboard:CHK" TRUE \
      --separator=$'\n' \
      --width=400 \
      --center 2>/dev/null)

    if [[ $? -eq 0 ]]; then
      new_name=$(echo "$result" | sed -n '1p')
      skip_frames=$(echo "$result" | sed -n '2p')
      copy_clip=$(echo "$result" | sed -n '3p')

      # Extract timestamp from original filename
      timestamp=$(basename "$recorded_file" .mp4 | sed 's/^screenrecording-//')

      # Rename if a name was provided
      if [[ -n "$new_name" ]]; then
        new_name="${new_name:0:$MAX_CHARS}"
        new_name=$(echo "$new_name" | sed 's/[\/]//g; s/^[[:space:]]*//; s/[[:space:]]*$//')
        new_path="$OUTPUT_DIR/${new_name}_${timestamp}.mp4"

        if [[ -f "$new_path" ]]; then
          new_path="$OUTPUT_DIR/${new_name}_${timestamp}_$(date +'%s').mp4"
        fi

        mv "$recorded_file" "$new_path"
        recorded_file="$new_path"
        notify-send "Recording saved" "$(basename "$new_path")" -t 2000
      fi

      # Apply post-processing
      clip_file="$recorded_file"
      if [[ "$skip_frames" == "TRUE" ]]; then
        base="${recorded_file%.mp4}"
        output="${base}--skipframes.mp4"
        notify-send "Processing" "Applying frame skip..." -t 2000
        (
          ffmpeg -i "$recorded_file" \
            -vf "select='mod(n\,2)',setpts=N/FRAME_RATE/TB" \
            -af "aselect='mod(n\,2)',asetpts=N/SR/TB" \
            "$output" -y 2>/dev/null
          if [[ $? -eq 0 ]]; then
            notify-send "Frame skip complete" "$(basename "$output")" -t 2000
            [[ "$copy_clip" == "TRUE" ]] && wl-copy < "$output"
          else
            notify-send "Frame skip failed" -u critical -t 3000
          fi
        ) &
      elif [[ "$copy_clip" == "TRUE" ]]; then
        wl-copy < "$recorded_file"
        notify-send "Copied to clipboard" "$(basename "$recorded_file")" -t 2000
      fi
    fi
  fi
else
  # Not recording — pass through to start
  omarchy-cmd-screenrecord "$@"
fi
