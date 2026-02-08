#!/bin/sh

# Full-width version of quran_verse.sh - shows more text (200 chars)

API_URL="https://api.quran.com/api/v4"
RANDOM_VERSE_ENDPOINT="/verses/random?translations=20&fields=text_uthmani"
CACHE_FILE="/tmp/quran_verse_cache.json"
CACHE_TTL=300  # seconds (5 minutes)

# Check if cache is fresh
if [ -f "$CACHE_FILE" ] && [ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_TTL ]; then
    response=$(cat "$CACHE_FILE")
else
    response=$(/usr/bin/curl -s "$API_URL$RANDOM_VERSE_ENDPOINT")
    echo "$response" > "$CACHE_FILE"
fi

verse_key=$(echo "$response" | /usr/bin/jq -r '.verse.verse_key')
translation=$(echo "$response" | /usr/bin/jq -r '.verse.translations[0].text')
uthmani_text=$(echo "$response" | /usr/bin/jq -r '.verse.text_uthmani')

# Clean translation for tooltip (remove HTML markup)
clean_translation=$(echo "$translation" | \
    sed 's/<[^>]*>//g' | \
    sed 's/\[[^]]*\]//g' | \
    sed 's/  */ /g' | \
    sed 's/^ *//' | \
    sed 's/ *$//')

# Create display text from first 180 characters
if [ ${#clean_translation} -gt 180 ]; then
    display_text="${clean_translation:0:180}..."
else
    display_text="$clean_translation"
fi

# Properly escape JSON values
display_text_escaped=$(echo "$display_text" | sed 's/"/\\"/g')
uthmani_escaped=$(echo "$uthmani_text" | sed 's/"/\\"/g')
translation_escaped=$(echo "$clean_translation" | sed 's/"/\\"/g')

echo "{\"text\": \"$display_text_escaped\", \"alt\": \"$uthmani_escaped\", \"tooltip\": \"$translation_escaped\"}"
