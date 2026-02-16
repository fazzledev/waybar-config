#!/bin/bash

# Location display and cycling script for waybar
# Reads from ~/.config/waybar/location.json
# Call with --cycle to advance to the next city

CONFIG="$HOME/.config/waybar/location.json"

# Preset cities (add more here)
CITIES=("Chennai" "Coimbatore")
COUNTRIES=("India" "India")

# Ensure config exists
if [ ! -f "$CONFIG" ]; then
    echo '{"city": "Chennai", "country": "India"}' > "$CONFIG"
fi

current_city=$(jq -r '.city' "$CONFIG")

if [ "$1" = "--cycle" ]; then
    # Find current index
    idx=0
    for i in "${!CITIES[@]}"; do
        if [ "${CITIES[$i]}" = "$current_city" ]; then
            idx=$i
            break
        fi
    done

    # Advance to next city
    next_idx=$(( (idx + 1) % ${#CITIES[@]} ))
    next_city="${CITIES[$next_idx]}"
    next_country="${COUNTRIES[$next_idx]}"

    # Write new config
    jq -n --arg city "$next_city" --arg country "$next_country" \
        '{"city": $city, "country": $country}' > "$CONFIG"

    # Signal waybar to refresh all modules (they check location.json themselves)
    pkill -RTMIN+9 waybar

    current_city="$next_city"
fi

# Output waybar JSON
echo "{\"text\": \" $current_city\", \"tooltip\": \"Location: $current_city\\nClick to switch city\"}"
