#!/bin/bash

# Speed up a segment of a video without losing quality
# Usage: speedup_segment.sh input.mp4 output.mp4 speed_factor start_time end_time

set -e

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

# 1. Extract segments
# Part 1: before start
ffmpeg -y -hide_banner -loglevel error -ss 0 -to "$START" -i "$INPUT" -c copy "$TMP1"

# Part 2: to be sped up
ffmpeg -y -hide_banner -loglevel error -ss "$START" -to "$END" -i "$INPUT" -c copy "$TMP2"

# Part 3: after end
ffmpeg -y -hide_banner -loglevel error -ss "$END" -i "$INPUT" -c copy "$TMP3"

# 2. Speed up the middle segment (video and audio if present)
# For video: setpts=PTS/SPEED
# For audio: atempo supports 0.5-2.0 per filter, so chain if needed

HAS_AUDIO=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$TMP2" | grep -c audio)

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

  ffmpeg -y -hide_banner -loglevel error -i "$TMP2" \
    -filter_complex "[0:v]setpts=PTS/$SPEED[v];[0:a]$ATEMPO_FILTER[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -crf 18 -preset veryfast -c:a aac -b:a 192k "${TMP2}.spedup.mp4"
else
  ffmpeg -y -hide_banner -loglevel error -i "$TMP2" \
    -filter_complex "[0:v]setpts=PTS/$SPEED[v]" \
    -map "[v]" -c:v libx264 -crf 18 -preset veryfast -an "${TMP2}.spedup.mp4"
fi

# 3. Prepare concat list
echo "file '$TMP1'" > "$TMP_LIST"
echo "file '${TMP2}.spedup.mp4'" >> "$TMP_LIST"
echo "file '$TMP3'" >> "$TMP_LIST"

# 4. Concatenate all parts
ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$TMP_LIST" -c copy "$OUTPUT"

echo "Output written to $OUTPUT"
