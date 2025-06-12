#!/bin/bash

# Terminal-to-PowerPoint Video Converter
# Creates 16:9 MP4 videos from terminal recordings with PowerPoint compatibility

# Load shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/cast2video_core.sh"

# Configuration
GEOMETRY="96x24"           # Terminal dimensions (very close to 16:9 for typical terminal fonts)
SCALE_FACTOR=4             # Reduced to prevent memory issues
FILENAME="terminal_recording_$(date +%Y%m%d_%H%M%S)"

# Check dependencies
check_dependency termtosvg
check_dependency docker
check_dependency ffmpeg

# Start recording
echo -e "\n\033[1;34m=== Starting Terminal Recording ===\033[0m"
echo "When finished, type 'exit' or press Ctrl+D"
termtosvg record -g "$GEOMETRY" "$FILENAME.cast" -c 'ssh -p 8022 -l poddingue 192.168.1.53'

# Create a temporary directory
tmp_dir=$(mktemp -d)

convert_cast_to_video "$FILENAME.cast" "$GEOMETRY" "$SCALE_FACTOR"
convert_to_16_9 "$FILENAME"
verify_and_cleanup "$FILENAME" "$tmp_dir"

# Final instructions
echo -e "\n\033[1;33mInsert into PowerPoint:\033[0m"
echo "1. Go to Insert > Video > Video on My PC"
echo "2. Select '${FILENAME}_ppt_16_9.mp4'"
echo "3. Right-click video → Playback → Set to:"
echo "   • Start: Automatically"
echo "   • Loop until Stopped"
