#!/bin/sh

API_URL="https://api.quran.com/api/v4"
RANDOM_VERSE_ENDPOINT="/verses/random?translations=20&fields=text_uthmani"

response=$(/usr/bin/curl -s "$API_URL$RANDOM_VERSE_ENDPOINT")

verse_key=$(echo "$response" | /usr/bin/jq -r '.verse.verse_key')
translation=$(echo "$response" | /usr/bin/jq -r '.verse.translations[0].text')
# Get the whole verse and remove special characters and symbols
clean_verse=$(echo "$translation" | sed 's/[^a-zA-Z0-9 ]//g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')

# Properly escape JSON values
clean_verse_escaped=$(echo "$clean_verse" | sed 's/"/\\"/g')
verse_key_escaped=$(echo "$verse_key" | sed 's/"/\\"/g')
translation_escaped=$(echo "$translation" | sed 's/"/\\"/g')

echo "{\"text\": \"$clean_verse_escaped\", \"alt\": \"$verse_key_escaped\", \"tooltip\": \"$translation_escaped\"}"

