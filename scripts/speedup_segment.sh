#!/bin/bash

# Speed up a segment of a video without losing quality
# Usage: speedup_segment.sh input.mp4 output.mp4 speed_factor start_time end_time

set -euo pipefail

log() {
  echo -e "\033[1;34m$1\033[0m"
}

error_exit() {
  echo -e "\033[1;31mERROR: $1\033[0m" >&2
  exit 1
}

if [ "$#" -ne 5 ]; then
  echo "Usage: $0 input.mp4 output.mp4 speed_factor start_time end_time"
  echo "Example: $0 input.mp4 output.mp4 2.0 00:01:00 00:02:00"
  exit 1
fi

INPUT="$1"
OUTPUT="$2"
SPEED="$3"
START="$4"
END="$5"

# Check dependencies
command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg is required but not installed."; exit 1; }

# Create temp files
TMP1=$(mktemp --suffix=.mp4)
TMP2=$(mktemp --suffix=.mp4)
TMP3=$(mktemp --suffix=.mp4)
TMP_LIST=$(mktemp)

cleanup() {
  rm -f "$TMP1" "$TMP2" "$TMP3" "$TMP_LIST"
}
trap cleanup EXIT

log "Extracting segment 1 (before $START)..."
set -x
ffmpeg -y -hide_banner -ss 0 -to "$START" -i "$INPUT" -c copy "$TMP1" || error_exit "Failed to extract segment 1"
set +x
log "Segment 1 extraction done."

log "Extracting segment 2 (from $START to $END)..."
set -x
ffmpeg -y -hide_banner -ss "$START" -to "$END" -i "$INPUT" -c copy "$TMP2" || error_exit "Failed to extract segment 2"
set +x
log "Segment 2 extraction done."

log "Extracting segment 3 (after $END)..."
set -x
ffmpeg -y -hide_banner -ss "$END" -i "$INPUT" -c copy "$TMP3" || error_exit "Failed to extract segment 3"
set +x
log "Segment 3 extraction done."

# 2. Speed up the middle segment (video and audio if present)
# For video: setpts=PTS/SPEED
# For audio: atempo supports 0.5-2.0 per filter, so chain if needed

log "Checking for audio in segment 2..."
set -x
FFPROBE_OUT=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$TMP2" || true)
set +x
log "ffprobe output: '$FFPROBE_OUT'"
HAS_AUDIO=0
if [[ "$FFPROBE_OUT" == *audio* ]]; then
  HAS_AUDIO=1
fi
log "HAS_AUDIO=$HAS_AUDIO"

log "Speeding up segment 2 ($START to $END) by $SPEED x..."
if [ "$HAS_AUDIO" -eq 1 ]; then
  ATEMPO_FILTER=""
  REMAINING_SPEED="$SPEED"
  while (( $(echo "$REMAINING_SPEED > 2.0" | bc -l) )); do
    ATEMPO_FILTER="${ATEMPO_FILTER}atempo=2.0,"
    REMAINING_SPEED=$(echo "$REMAINING_SPEED / 2.0" | bc -l)
  done
  while (( $(echo "$REMAINING_SPEED < 0.5" | bc -l) )); do
    ATEMPO_FILTER="${ATEMPO_FILTER}atempo=0.5,"
    REMAINING_SPEED=$(echo "$REMAINING_SPEED / 0.5" | bc -l)
  done
  ATEMPO_FILTER="${ATEMPO_FILTER}atempo=$REMAINING_SPEED"

  set -x
  ffmpeg -y -hide_banner -i "$TMP2" \
    -filter_complex "[0:v]setpts=PTS/$SPEED[v];[0:a]$ATEMPO_FILTER[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset veryfast -c:a aac -b:a 192k "${TMP2}.spedup.mp4" || error_exit "Failed to speed up segment 2 (with audio)"
  set +x
else
  set -x
  ffmpeg -y -hide_banner -i "$TMP2" \
    -filter_complex "[0:v]setpts=PTS/$SPEED[v]" \
    -map "[v]" -c:v libx264 -crf 18 -preset veryfast -an "${TMP2}.spedup.mp4" || error_exit "Failed to speed up segment 2 (video only)"
  set +x
fi
log "Segment 2 speed-up done."

log "Preparing concat list..."
echo "file '$TMP1'" > "$TMP_LIST"
echo "file '${TMP2}.spedup.mp4'" >> "$TMP_LIST"
echo "file '$TMP3'" >> "$TMP_LIST"
log "Concat list prepared."

log "Concatenating all segments into final output..."
set -x
ffmpeg -y -hide_banner -f concat -safe 0 -i "$TMP_LIST" -c copy "$OUTPUT" || error_exit "Failed to concatenate segments"
set +x

log "Output written to $OUTPUT"
