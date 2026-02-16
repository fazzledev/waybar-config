#!/bin/bash

# Location display and cycling script for waybar
# Auto-detects city from IP on first run, click cycles through presets
# Reads/writes ~/.config/waybar/location.json

CONFIG="$HOME/.config/waybar/location.json"

# Preset cities for manual cycling (add more here)
CITIES=("Chennai" "Coimbatore")
COUNTRIES=("India" "India")

# Auto-detect city from IP geolocation
auto_detect() {
    local geo
    geo=$(curl -sL --max-time 5 "https://ipinfo.io/json" 2>/dev/null)
    if [ -n "$geo" ]; then
        local city country
        city=$(echo "$geo" | jq -r '.city // empty')
        country=$(echo "$geo" | jq -r '.country // empty')
        if [ -n "$city" ] && [ -n "$country" ]; then
            jq -n --arg city "$city" --arg country "$country" \
                '{"city": $city, "country": $country}' > "$CONFIG"
            return 0
        fi
    fi
    return 1
}

# Auto-detect on first run (no config file yet)
if [ ! -f "$CONFIG" ]; then
    if ! auto_detect; then
        echo '{"city": "Chennai", "country": "India"}' > "$CONFIG"
    fi
fi

current_city=$(jq -r '.city' "$CONFIG")

if [ "$1" = "--cycle" ]; then
    # Find current index (-1 if not in presets, e.g. auto-detected city)
    idx=-1
    for i in "${!CITIES[@]}"; do
        if [ "${CITIES[$i]}" = "$current_city" ]; then
            idx=$i
            break
        fi
    done

    # Advance to next preset city
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
