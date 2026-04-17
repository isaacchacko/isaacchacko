#!/usr/bin/env bash
set -euo pipefail

README_PATH="README.md"
README_TEMPLATE_PATH="README.template.md"
CITY="${CITY:-College Station, TX}"
PROFILE_USERNAME="${PROFILE_USERNAME:-isaacchacko}"

# --- Weather from wttr.in (no API key needed) ---
# Example payload includes current_condition[0].temp_F and weatherDesc[0].value
CITY_ENCODED="$(jq -nr --arg city "$CITY" '$city|@uri')"
WEATHER_JSON="$(curl -fsSL "https://wttr.in/${CITY_ENCODED}?format=j1")"
TEMP_F="$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].temp_F')"
WEATHER_DESC="$(echo "$WEATHER_JSON" | jq -r '.current_condition[0].weatherDesc[0].value')"

if [[ -z "$TEMP_F" || "$TEMP_F" == "null" ]]; then
  TEMP_F="N/A"
fi
if [[ -z "$WEATHER_DESC" || "$WEATHER_DESC" == "null" ]]; then
  WEATHER_DESC="Unknown"
fi

# --- Profile view count (Komarev profile README counter) ---
# Pull the SVG and parse "NNN" from text like: "Profile views: 1234"
VIEW_SVG="$(curl -fsSL "https://komarev.com/ghpvc/?username=${PROFILE_USERNAME}&label=Profile%20views&color=0e75b6&style=flat")"
VIEW_COUNT="$(echo "$VIEW_SVG" | sed -n 's/.*Profile views: \([0-9][0-9,]*\).*/\1/p' | head -n1)"

if [[ -z "$VIEW_COUNT" ]]; then
  VIEW_COUNT="N/A"
fi

TIMESTAMP="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"

if [[ ! -f "$README_TEMPLATE_PATH" ]]; then
  echo "Template not found: $README_TEMPLATE_PATH"
  exit 1
fi

cp "$README_TEMPLATE_PATH" "$README_PATH"

# Escape replacement strings for sed
escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

TEMP_ESCAPED="$(escape_sed "$TEMP_F")"
DESC_ESCAPED="$(escape_sed "$WEATHER_DESC")"
VIEW_ESCAPED="$(escape_sed "$VIEW_COUNT")"
TS_ESCAPED="$(escape_sed "$TIMESTAMP")"

# Replace placeholders in README copied from template.
sed -i "s/\$weatherInDegrees/${TEMP_ESCAPED}/g" "$README_PATH"
sed -i "s/\$verbalWeatherDescrip/${DESC_ESCAPED}/g" "$README_PATH"
sed -i "s/\$viewCount/${VIEW_ESCAPED}/g" "$README_PATH"
sed -i "s/\$timestamp/${TS_ESCAPED}/g" "$README_PATH"

echo "README updated:"
echo "  CITY=$CITY"
echo "  TEMP_F=$TEMP_F"
echo "  WEATHER_DESC=$WEATHER_DESC"
echo "  VIEW_COUNT=$VIEW_COUNT"
echo "  TIMESTAMP=$TIMESTAMP"
