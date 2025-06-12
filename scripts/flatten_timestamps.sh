#!/usr/bin/env bash

# Usage: ./flatten_timestamps.sh input.cast start_timestamp end_timestamp output.cast
# - input.cast:         Input .cast file (asciinema format)
# - start_timestamp:    Start of range (inclusive)
# - end_timestamp:      End of range (inclusive)
# - output.cast:        Output file path

set -e

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 input.cast start_timestamp end_timestamp output.cast"
  exit 1
fi

input="$1"
start_ts="$2"
end_ts="$3"
output="$4"

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

gawk -v start_ts="$start_ts" -v end_ts="$end_ts" '
{
  line = $0
  # Pass through header lines (JSON objects) unchanged
  if (line ~ /^\{/) {
    print line
    next
  }
  # Extract the timestamp (first number in the JSON array)
  if (match(line, /^\[([0-9]+\.[0-9]+)/, arr)) {
    ts = arr[1] + 0
    if (ts >= start_ts && ts <= end_ts) {
      # Set timestamp to start_ts
      sub(/^\[[0-9]+\.[0-9]+/, "[" sprintf("%.6f", start_ts), line)
      print line
    } else {
      print line
    }
  } else {
    print line > "/dev/stderr"
    print "Error: Could not parse timestamp on line " NR > "/dev/stderr"
    exit 2
  }
}
' "$input" > "$output"
