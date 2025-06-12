#!/usr/bin/env bash

# Usage: ./shorten_gap.sh input.cast target_timestamp output.cast [gap]
# - input.cast:         Input .cast file (one JSON array per line)
# - target_timestamp:   Timestamp to adjust (e.g., 231.281972)
# - output.cast:        Output file path
# - gap (optional):     Custom gap in seconds (default: "next half second")

set -e

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 input.cast target_timestamp output.cast [gap]"
  exit 1
fi

input="$1"
target_ts="$2"
output="$3"
gap="$4"

# Use gawk for compatibility, attempt to install if missing
if ! command -v gawk >/dev/null 2>&1; then
  echo "gawk is required but not installed. Attempting to install..."

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y gawk
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y gawk
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y gawk
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy --noconfirm gawk
  elif command -v brew >/dev/null 2>&1; then
    brew install gawk
  elif command -v choco >/dev/null 2>&1; then
    choco install gawk -y
  else
    echo "Automatic installation failed: No supported package manager found."
    echo "Please install gawk manually and re-run the script."
    exit 2
  fi

  # Re-check after attempted install
  if ! command -v gawk >/dev/null 2>&1; then
    echo "gawk installation failed. Please install it manually and re-run the script."
    exit 2
  fi
fi

gawk -v target_ts="$target_ts" -v gap="$gap" '
function ceil_half(x) {
  # Returns x rounded up to the next 0.5
  return (int(x * 2 + 0.999999) / 2.0)
}
BEGIN {
  found = 0
  shift_amt = 0
}
{
  line = $0
  # Pass through header lines (JSON objects) unchanged
  if (line ~ /^\{/) {
    header_lines[header_count++] = line
    next
  }
  # Extract the timestamp (first number in the JSON array)
  if (match(line, /^\[([0-9]+\.[0-9]+)/, arr)) {
    ts = arr[1] + 0
    timestamps[event_count+1] = ts
    lines[event_count+1] = line
    event_count++
    nlines = event_count
  } else {
    print line > "/dev/stderr"
    print "Error: Could not parse timestamp on line " NR > "/dev/stderr"
    exit 2
  }
}
END {
  # Print header lines first
  for (h = 0; h < header_count; h++) {
    print header_lines[h]
  }

  for (i = 1; i <= nlines; i++) {
    ts = timestamps[i]
    if (!found && (ts == target_ts + 0)) {
      if (i == 1) {
        print lines[i]
        found = 1
        continue
      }
      prev_ts = timestamps[i-1]
      diff = ts - prev_ts
      if (gap == "") {
        # Default: next half second after prev_ts
        new_ts = ceil_half(prev_ts)
        if (new_ts <= prev_ts) new_ts = prev_ts + 0.5
        target_gap = new_ts - prev_ts
      } else {
        target_gap = gap + 0
        new_ts = prev_ts + target_gap
      }
      shift_amt = ts - new_ts
      # Print previous lines unchanged
      for (j = 1; j < i; j++) {
        print lines[j]
      }
      # Print this and subsequent lines with shifted timestamps
      for (j = i; j <= nlines; j++) {
        orig_line = lines[j]
        orig_ts = timestamps[j]
        new_ts = orig_ts - shift_amt
        # Replace the timestamp in the line
        sub(/^\[[0-9]+\.[0-9]+/, "[" sprintf("%.6f", new_ts), orig_line)
        print orig_line
      }
      found = 1
      break
    }
  }
  if (!found) {
    # If not found, print all event lines unchanged
    for (i = 1; i <= nlines; i++) {
      print lines[i]
    }
  }
}
' "$input" > "$output"
