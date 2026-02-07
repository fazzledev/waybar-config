#!/bin/bash

# Salah times script using Aladhan API
# Displays next prayer with countdown

CACHE_FILE="/tmp/salah_times_cache.json"
CACHE_TTL=3600  # 1 hour cache for prayer times

# Coimbatore coordinates
LAT="11.0168"
LON="76.9558"
METHOD="1"  # Muslim World League

# Get current date
TODAY=$(date +%d-%m-%Y)

# Check if cache is fresh and for today
if [ -f "$CACHE_FILE" ]; then
    CACHE_DATE=$(jq -r '.date.gregorian.date' "$CACHE_FILE" 2>/dev/null)
    CACHE_AGE=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE")))
    if [ "$CACHE_DATE" = "$TODAY" ] && [ $CACHE_AGE -lt $CACHE_TTL ]; then
        response=$(cat "$CACHE_FILE")
    else
        response=""
    fi
else
    response=""
fi

# Fetch new data if needed
if [ -z "$response" ]; then
    # Fetch prayer times from Aladhan
    api_response=$(curl -sL --max-time 15 "https://api.aladhan.com/v1/timingsByCity?city=Coimbatore&country=India&method=$METHOD" 2>/dev/null)

    if [ -n "$api_response" ]; then
        echo "$api_response" | jq '.data' > "$CACHE_FILE" 2>/dev/null
        response=$(cat "$CACHE_FILE")
    fi
fi

# Check if we have valid data
if [ -z "$response" ] || [ "$response" = "null" ]; then
    echo '{"text": "󰥔 --:--", "tooltip": "Prayer times unavailable"}'
    exit 0
fi

# Extract prayer times
fajr=$(echo "$response" | jq -r '.timings.Fajr' | cut -d' ' -f1)
sunrise=$(echo "$response" | jq -r '.timings.Sunrise' | cut -d' ' -f1)
dhuhr=$(echo "$response" | jq -r '.timings.Dhuhr' | cut -d' ' -f1)
asr=$(echo "$response" | jq -r '.timings.Asr' | cut -d' ' -f1)
maghrib=$(echo "$response" | jq -r '.timings.Maghrib' | cut -d' ' -f1)
isha=$(echo "$response" | jq -r '.timings.Isha' | cut -d' ' -f1)

# Check if we got valid times
if [ "$fajr" = "null" ] || [ -z "$fajr" ]; then
    echo '{"text": "󰥔 --:--", "tooltip": "Invalid prayer times"}'
    exit 0
fi

# Current time in minutes since midnight
now_h=$(date +%H)
now_m=$(date +%M)
now_mins=$((10#$now_h * 60 + 10#$now_m))

# Convert prayer time to minutes
to_mins() {
    local time=$1
    local h=$(echo "$time" | cut -d: -f1)
    local m=$(echo "$time" | cut -d: -f2)
    echo $((10#$h * 60 + 10#$m))
}

fajr_mins=$(to_mins "$fajr")
sunrise_mins=$(to_mins "$sunrise")
dhuhr_mins=$(to_mins "$dhuhr")
asr_mins=$(to_mins "$asr")
maghrib_mins=$(to_mins "$maghrib")
isha_mins=$(to_mins "$isha")

# Find next prayer
next_prayer=""
next_time=""
mins_until=0

if [ $now_mins -lt $fajr_mins ]; then
    next_prayer="Fajr"
    next_time="$fajr"
    mins_until=$((fajr_mins - now_mins))
elif [ $now_mins -lt $sunrise_mins ]; then
    next_prayer="Sunrise"
    next_time="$sunrise"
    mins_until=$((sunrise_mins - now_mins))
elif [ $now_mins -lt $dhuhr_mins ]; then
    next_prayer="Dhuhr"
    next_time="$dhuhr"
    mins_until=$((dhuhr_mins - now_mins))
elif [ $now_mins -lt $asr_mins ]; then
    next_prayer="Asr"
    next_time="$asr"
    mins_until=$((asr_mins - now_mins))
elif [ $now_mins -lt $maghrib_mins ]; then
    next_prayer="Maghrib"
    next_time="$maghrib"
    mins_until=$((maghrib_mins - now_mins))
elif [ $now_mins -lt $isha_mins ]; then
    next_prayer="Isha"
    next_time="$isha"
    mins_until=$((isha_mins - now_mins))
else
    # After Isha, next is Fajr tomorrow
    next_prayer="Fajr"
    next_time="$fajr"
    mins_until=$((1440 - now_mins + fajr_mins))
fi

# Format countdown
hours=$((mins_until / 60))
mins=$((mins_until % 60))

if [ $hours -gt 0 ]; then
    countdown="${hours}h ${mins}m"
else
    countdown="${mins}m"
fi

# Build tooltip with all times
tooltip="Fajr: $fajr\nSunrise: $sunrise\nDhuhr: $dhuhr\nAsr: $asr\nMaghrib: $maghrib\nIsha: $isha"

# Output JSON
echo "{\"text\": \"󰥔 Coimbatore · $next_prayer in $countdown\", \"tooltip\": \"$tooltip\"}"
