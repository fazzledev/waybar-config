#!/bin/sh

# Debug mode - enable with --debug flag
DEBUG=false
if [ "$1" = "--debug" ]; then
    DEBUG=true
fi

API_URL="https://api.quran.com/api/v4"
RANDOM_VERSE_ENDPOINT="/verses/random?translations=20&fields=text_uthmani"

if [ "$DEBUG" = true ]; then
    echo "DEBUG: Fetching verse from API..." >&2
fi

response=$(/usr/bin/curl -s "$API_URL$RANDOM_VERSE_ENDPOINT")

if [ "$DEBUG" = true ]; then
    echo "DEBUG: Raw API response:" >&2
    echo "$response" | jq . >&2
fi

verse_key=$(echo "$response" | /usr/bin/jq -r '.verse.verse_key')
translation=$(echo "$response" | /usr/bin/jq -r '.verse.translations[0].text')

if [ "$DEBUG" = true ]; then
    echo "DEBUG: Verse key: $verse_key" >&2
    echo "DEBUG: Original translation: $translation" >&2
fi

# Get the whole verse and clean it intelligently
clean_verse=$(echo "$translation" | \
    sed 's/<[^>]*>//g' | \
    sed 's/\[[^]]*\]//g' | \
    sed 's/"[^"]*"//g' | \
    sed 's/[()]//g' | \
    sed 's/[.,;:!]//g' | \
    sed 's/  */ /g' | \
    sed 's/^ *//' | \
    sed 's/ *$//')

if [ "$DEBUG" = true ]; then
    echo "DEBUG: Cleaned verse: $clean_verse" >&2
    echo "DEBUG: Clean verse length: ${#clean_verse}" >&2
fi

# Create carousel effect by truncating long text and adding ellipsis
if [ ${#clean_verse} -gt 50 ]; then
    # Show first 50 characters with ellipsis
    display_text="${clean_verse:0:50}..."
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: Text truncated to: $display_text" >&2
    fi
else
    display_text="$clean_verse"
    if [ "$DEBUG" = true ]; then
        echo "DEBUG: Text not truncated" >&2
    fi
fi

# Properly escape JSON values
display_text_escaped=$(echo "$display_text" | sed 's/"/\\"/g')
verse_key_escaped=$(echo "$verse_key" | sed 's/"/\\"/g')
translation_escaped=$(echo "$translation" | sed 's/"/\\"/g')

if [ "$DEBUG" = true ]; then
    echo "DEBUG: Final JSON output:" >&2
fi

echo "{\"text\": \"$display_text_escaped\", \"alt\": \"$verse_key_escaped\", \"tooltip\": \"$translation_escaped\"}"


