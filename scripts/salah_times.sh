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

# Prayer names and times in order (excluding sunrise for "just passed" check)
prayers=("Fajr" "Sunrise" "Dhuhr" "Asr" "Maghrib" "Isha")
times=("$fajr" "$fajr" "$dhuhr" "$asr" "$maghrib" "$isha")
mins_arr=($fajr_mins $sunrise_mins $dhuhr_mins $asr_mins $maghrib_mins $isha_mins)

# Check if a prayer just passed (within 30 mins) - skip Sunrise
check_just_passed() {
    local prayer_names=("Fajr" "Dhuhr" "Asr" "Maghrib" "Isha")
    local prayer_mins=($fajr_mins $dhuhr_mins $asr_mins $maghrib_mins $isha_mins)

    for i in "${!prayer_names[@]}"; do
        local p_mins=${prayer_mins[$i]}
        local mins_since=$((now_mins - p_mins))
        if [ $mins_since -ge 0 ] && [ $mins_since -le 30 ]; then
            echo "${prayer_names[$i]}|$mins_since"
            return 0
        fi
    done
    echo ""
}

# Find next prayer
find_next_prayer() {
    if [ $now_mins -lt $fajr_mins ]; then
        echo "Fajr|$fajr|$((fajr_mins - now_mins))"
    elif [ $now_mins -lt $sunrise_mins ]; then
        echo "Sunrise|$sunrise|$((sunrise_mins - now_mins))"
    elif [ $now_mins -lt $dhuhr_mins ]; then
        echo "Dhuhr|$dhuhr|$((dhuhr_mins - now_mins))"
    elif [ $now_mins -lt $asr_mins ]; then
        echo "Asr|$asr|$((asr_mins - now_mins))"
    elif [ $now_mins -lt $maghrib_mins ]; then
        echo "Maghrib|$maghrib|$((maghrib_mins - now_mins))"
    elif [ $now_mins -lt $isha_mins ]; then
        echo "Isha|$isha|$((isha_mins - now_mins))"
    else
        echo "Fajr|$fajr|$((1440 - now_mins + fajr_mins))"
    fi
}

# Build tooltip with all times
tooltip="Fajr: $fajr\nSunrise: $sunrise\nDhuhr: $dhuhr\nAsr: $asr\nMaghrib: $maghrib\nIsha: $isha"

# Check for just-passed prayer first
just_passed=$(check_just_passed)

if [ -n "$just_passed" ]; then
    prayer_name=$(echo "$just_passed" | cut -d'|' -f1)
    mins_ago=$(echo "$just_passed" | cut -d'|' -f2)
    echo "{\"text\": \"󰥔 Coimbatore · $prayer_name ${mins_ago}m ago\", \"tooltip\": \"$tooltip\", \"class\": \"urgent\"}"
else
    # Get next prayer
    next_info=$(find_next_prayer)
    next_prayer=$(echo "$next_info" | cut -d'|' -f1)
    next_time=$(echo "$next_info" | cut -d'|' -f2)
    mins_until=$(echo "$next_info" | cut -d'|' -f3)

    # Format countdown
    hours=$((mins_until / 60))
    mins=$((mins_until % 60))

    if [ $hours -gt 0 ]; then
        countdown="${hours}h ${mins}m"
    else
        countdown="${mins}m"
    fi

    # Determine class based on time remaining
    if [ $mins_until -le 30 ]; then
        echo "{\"text\": \"󰥔 Coimbatore · $next_prayer in $countdown\", \"tooltip\": \"$tooltip\", \"class\": \"warning\"}"
    else
        echo "{\"text\": \"󰥔 Coimbatore · $next_prayer in $countdown\", \"tooltip\": \"$tooltip\"}"
    fi
fi
