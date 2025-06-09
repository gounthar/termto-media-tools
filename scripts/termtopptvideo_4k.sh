#!/bin/bash

# Terminal-to-PowerPoint Video Converter (4K Version)
# Creates 4K 16:9 MP4 videos from terminal recordings with PowerPoint compatibility

# Configuration
# For a true 16:9 output, columns/rows ≈ 3.96 (based on measured char aspect ≈ 0.45 from previous renders).
# 192x48 should yield a rendered aspect ratio very close to 16:9 with minimal padding for 4K.
GEOMETRY="192x48"           # Terminal dimensions (very close to 16:9 for typical terminal fonts, high-res for 4K)
SCALE_FACTOR=4              # Reduced to prevent memory issues
OUTPUT_RES="3840x2160"      # Output resolution (4K, 16:9)
FILENAME="terminal_recording_$(date +%Y%m%d_%H%M%S)"
DEFAULT_DURATION=60         # Default duration in seconds

# Check dependencies
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 not installed. Please install it first."
        exit 1
    fi
}

check_dependency termtosvg
check_dependency docker
check_dependency ffmpeg

# Start recording
echo -e "\n\033[1;34m=== Starting Terminal Recording (4K) ===\033[0m"
echo "When finished, type 'exit' or press Ctrl+D"
termtosvg record -g "$GEOMETRY" "$FILENAME.cast" -c 'ssh -p 8022 -l poddingue 192.168.1.53'

# Create a temporary directory
tmp_dir=$(mktemp -d)
echo -e "\n\033[1;34m=== Converting to 4K MP4 ===\033[0m"

# Only use Docker as a fallback if the direct conversion failed
if [ ! -f "${FILENAME}_ppt.mp4" ] || [ ! -s "${FILENAME}_ppt.mp4" ]; then
  echo "Running: docker run --rm -v \"$PWD:/data\" beer5215/asciicast2mp4 -S $SCALE_FACTOR -w \"${GEOMETRY%x*}\" -h \"${GEOMETRY#*x}\" \"$FILENAME.cast\""
  docker run --rm -v "$PWD:/data" beer5215/asciicast2mp4 -S $SCALE_FACTOR \
    -w "${GEOMETRY%x*}" -h "${GEOMETRY#*x}" "$FILENAME.cast"
  [ -f $tmp_dir/result.mp4 ] && mv $tmp_dir/result.mp4 "${FILENAME}_ppt.mp4"
  # --- PATCH: Also check for result.mp4 in subdirectory named after FILENAME
  if [ -f "${FILENAME}/result.mp4" ]; then
    mv "${FILENAME}/result.mp4" "${FILENAME}_ppt.mp4"
  fi
fi

# Always produce a 4K 16:9 PowerPoint-compatible video using ffmpeg
ffmpeg -y -i "${FILENAME}_ppt.mp4" -vf "scale=w=3840:h=2160:force_original_aspect_ratio=decrease,pad=3840:2160:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -an -movflags +faststart -preset slow "${FILENAME}_ppt_4k_16_9.mp4"

# Verification
if [ -f "${FILENAME}_ppt_4k_16_9.mp4" ] && [ -s "${FILENAME}_ppt_4k_16_9.mp4" ]; then
  echo -e "\n\033[1;32m=== 4K Conversion Complete ===\033[0m"
  echo -e "Output file: \033[1;35m${FILENAME}_ppt_4k_16_9.mp4\033[0m"
  # Verify dimensions and aspect ratio
  echo -n "Verifying format: "
  ffprobe_out=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,display_aspect_ratio -of csv=s=x:p=0 "${FILENAME}_ppt_4k_16_9.mp4")
  echo "$ffprobe_out"
  width=$(echo "$ffprobe_out" | cut -d'x' -f1)
  height=$(echo "$ffprobe_out" | cut -d'x' -f2)
  dar=$(echo "$ffprobe_out" | cut -d'x' -f3)
  # Check if width:height is 3840:2160 (16:9)
  if [ "$width" = "3840" ] && [ "$height" = "2160" ]; then
    echo -e "\033[1;32mConfirmed: Output is 3840x2160 (16:9, 4K)\033[0m"
  else
    echo -e "\033[1;33mWarning: Output is $width x $height (DAR $dar), not exactly 3840x2160 (16:9)\033[0m"
  fi
  # Clean up intermediary files if everything went fine
  if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
    echo "Deleting temp directory: $tmp_dir"
    rm -rf -- "$tmp_dir"
    if [ -d "$tmp_dir" ]; then
      echo -e "\033[1;33mWarning: Temp directory $tmp_dir could not be deleted.\033[0m"
    fi
  fi
  [ -f "${FILENAME}.cast" ] && rm -f "${FILENAME}.cast"
  [ -f "${FILENAME}_ppt.mp4" ] && rm -f "${FILENAME}_ppt.mp4"
  [ -f "${FILENAME}/result.mp4" ] && rm -f "${FILENAME}/result.mp4"
else
  echo -e "\n\033[1;31m=== 4K Conversion Failed ===\033[0m"
  echo "No output file created. Check logs."
  exit 1
fi

# Final instructions
echo -e "\n\033[1;33mInsert into PowerPoint:\033[0m"
echo "1. Go to Insert > Video > Video on My PC"
echo "2. Select '${FILENAME}_ppt_4k_16_9.mp4'"
echo "3. Right-click video → Playback → Set to:"
echo "   • Start: Automatically"
echo "   • Loop until Stopped"