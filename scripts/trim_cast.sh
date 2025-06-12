#!/bin/bash
# Usage: ./trim_cast.sh input.cast start_time end_time output.cast
# Removes all events with timestamps >= start_time and < end_time,
# keeps all others, rebases timestamps so the first kept event is at 0,
# and writes to output.cast with the header unchanged.

set -e

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 input.cast start_time end_time output.cast"
  exit 1
fi

input="$1"
start="$2"
end="$3"
output="$4"

# Read and write the header (first line) unchanged
head -n 1 "$input" > "$output"

# Buffer kept events and their timestamps
events=()
timestamps=()

while IFS= read -r line; do
  # Remove leading/trailing whitespace and carriage returns
  line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]\r]*$//')"
  # Skip empty lines
  [ -z "$line" ] && continue
  # Check if line is a JSON array (starts with [)
  if [[ "$line" =~ ^\[ ]]; then
    # Try to extract timestamp with jq
    ts=$(echo "$line" | jq '.[0]' 2>/dev/null) || { echo "DEBUG: jq failed for line: $line" >&2; continue; }
    # Ensure ts is a valid number (jq outputs null for invalid)
    if [[ "$ts" == "null" || -z "$ts" ]]; then
      echo "DEBUG: Invalid ts for line: $line" >&2
      continue
    fi
    # Compare numerically in bash
    keep=0
    awk_result=$(awk -v ts="$ts" -v start="$start" -v end="$end" 'BEGIN { if (ts < start || ts >= end) print 1; else print 0 }')
    if [ "$awk_result" -eq 1 ]; then
      keep=1
    fi
    if [ "$keep" -eq 1 ]; then
      events+=("$line")
      timestamps+=("$ts")
      echo "DEBUG: Keeping event with ts=$ts, line: $line" >&2
    else
      echo "DEBUG: Removing event with ts=$ts, line: $line" >&2
    fi
  else
    echo "DEBUG: Skipping non-event line: $line" >&2
    continue
  fi
done < <(tail -n +2 "$input")

# Find the timestamp of the first kept event
first_ts=""
for ts in "${timestamps[@]}"; do
  if [ -n "$ts" ]; then
    first_ts="$ts"
    break
  fi
done

# If no events remain, we're done
if [ -z "$first_ts" ]; then
  echo "DEBUG: No events remain after filtering." >&2
  exit 0
fi

# Output rebased events
for i in "${!events[@]}"; do
  ts="${timestamps[$i]}"
  event="${events[$i]}"
  newts=$(awk -v ts="$ts" -v first="$first_ts" 'BEGIN { printf "%.6f", ts - first }')
  echo "DEBUG: Rebasing event ts=$ts to newts=$newts, line: $event" >&2
  echo "$event" | jq -c --argjson t "$newts" '.[0]=$t' >> "$output"
done
