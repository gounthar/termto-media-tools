#!/bin/bash

# Usage: ./cast2video.sh input.cast
# Converts a .cast file to a PowerPoint-compatible 16:9 MP4 video

# Load shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cast2video_core.sh"

# Check arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 input.cast"
  exit 1
fi

INPUT_CAST="$1"
BASENAME="${INPUT_CAST%.cast}"
GEOMETRY="96x24"           # Should match the geometry used for recording
SCALE_FACTOR=4

check_dependency docker
check_dependency ffmpeg

# Create a temporary directory
tmp_dir=$(mktemp -d)

convert_cast_to_video "$INPUT_CAST" "$GEOMETRY" "$SCALE_FACTOR"
convert_to_16_9 "$BASENAME"
verify_and_cleanup "$BASENAME" "$tmp_dir"

# Final instructions
echo -e "\n\033[1;33mInsert into PowerPoint:\033[0m"
echo "1. Go to Insert > Video > Video on My PC"
echo "2. Select '${BASENAME}_ppt_16_9.mp4'"
echo "3. Right-click video → Playback → Set to:"
echo "   • Start: Automatically"
echo "   • Loop until Stopped"
