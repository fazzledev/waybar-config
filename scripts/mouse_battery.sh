#!/bin/bash

DEVICE="/org/freedesktop/UPower/devices/battery_hidpp_battery_0"
BATTERY=$(upower -i "$DEVICE" | awk '/percentage/ { print $2 }')

# Output JSON so Waybar can parse it
echo "{\"text\": \"󰍽\", \"class\": \"mouse-battery\", \"tooltip\": \"Mouse Battery: $BATTERY\"}"
