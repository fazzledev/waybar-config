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
      --field="Compress to 10MB:CHK" TRUE \
      --field="Skip frames:CHK" TRUE \
      --field="Copy path to clipboard:CHK" TRUE \
      --field="Auto-delete:CHK" TRUE \
      --field="Delete after (minutes):NUM" "3!1..60!1" \
      --separator=$'\n' \
      --width=400 \
      --center 2>/dev/null)

    if [[ $? -eq 0 ]]; then
      new_name=$(echo "$result" | sed -n '1p')
      compress=$(echo "$result" | sed -n '2p')
      skip_frames=$(echo "$result" | sed -n '3p')
      copy_path=$(echo "$result" | sed -n '4p')
      auto_delete_on=$(echo "$result" | sed -n '5p')
      auto_delete=$(echo "$result" | sed -n '6p')

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

      original_file="$recorded_file"

      # Compress to 10MB
      if [[ "$compress" == "TRUE" ]]; then
        duration=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$recorded_file" 2>/dev/null)
        duration=${duration%.*}
        if [[ "$duration" -gt 0 ]] 2>/dev/null; then
          target_bitrate=$(( 10 * 8 * 1024 / duration ))k
          compressed="${recorded_file%.mp4}--compressed.mp4"
          notify-send "Processing" "Compressing to 10MB..." -t 2000
          ffmpeg -i "$recorded_file" -b:v "$target_bitrate" -maxrate "$target_bitrate" \
            -bufsize "$(( 10 * 1024 ))k" "$compressed" -y 2>/dev/null
          if [[ $? -eq 0 ]]; then
            notify-send "Compression complete" "$(basename "$compressed")" -t 2000
            recorded_file="$compressed"
          else
            notify-send "Compression failed" -u critical -t 3000
          fi
        fi
      fi

      # Skip frames
      if [[ "$skip_frames" == "TRUE" ]]; then
        base="${recorded_file%.mp4}"
        output="${base}--skipframes.mp4"
        notify-send "Processing" "Applying frame skip..." -t 2000
        ffmpeg -i "$recorded_file" \
          -vf "select='mod(n\,2)',setpts=N/FRAME_RATE/TB" \
          -af "aselect='mod(n\,2)',asetpts=N/SR/TB" \
          "$output" -y 2>/dev/null
        if [[ $? -eq 0 ]]; then
          notify-send "Frame skip complete" "$(basename "$output")" -t 2000
          recorded_file="$output"
        else
          notify-send "Frame skip failed" -u critical -t 3000
        fi
      fi

      # Copy final file path to clipboard
      if [[ "$copy_path" == "TRUE" ]]; then
        echo -n "$recorded_file" | wl-copy
      fi

      # Schedule auto-delete via systemd timer (cleans up all generated files)
      auto_delete=${auto_delete%.*}  # strip decimal from yad NUM field
      if [[ "$auto_delete_on" == "TRUE" && "$auto_delete" -gt 0 ]] 2>/dev/null; then
        delete_cmd="rm -f '${original_file}'* && notify-send 'Recording deleted' '$(basename "$original_file")' -t 2000"
        # Cancel any previous auto-delete timer
        systemctl --user stop screenrecord-autodelete.timer 2>/dev/null
        systemd-run --user --unit=screenrecord-autodelete --on-active="${auto_delete}m" bash -c "$delete_cmd"
      fi
    fi
  fi
else
  # Not recording — pass through to start
  omarchy-cmd-screenrecord "$@"
fi
