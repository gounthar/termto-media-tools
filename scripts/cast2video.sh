#!/bin/bash

# Usage: ./cast2video.sh input.cast
# Converts a .cast file to a PowerPoint-compatible 16:9 MP4 video

# Check arguments
if [ $# -ne 1 ]; then
  echo "Usage: $0 input.cast"
  exit 1
fi

INPUT_CAST="$1"
BASENAME="${INPUT_CAST%.cast}"
GEOMETRY="96x24"           # Should match the geometry used for recording
SCALE_FACTOR=4
OUTPUT_RES="1920x1080"

# Check dependencies
check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 not installed. Please install it first."
        exit 1
    fi
}

check_dependency docker
check_dependency ffmpeg

# Create a temporary directory
tmp_dir=$(mktemp -d)
echo -e "\n\033[1;34m=== Converting .cast to MP4 ===\033[0m"

# Convert .cast to mp4 using Docker/asciicast2mp4
echo "Running: docker run --rm -v \"$PWD:/data\" beer5215/asciicast2mp4 -S $SCALE_FACTOR -w \"${GEOMETRY%x*}\" -h \"${GEOMETRY#*x}\" \"$INPUT_CAST\""
docker run --rm -v "$PWD:/data" beer5215/asciicast2mp4 -S $SCALE_FACTOR \
  -w "${GEOMETRY%x*}" -h "${GEOMETRY#*x}" "$INPUT_CAST"

# Move result.mp4 if found
if [ -f "$tmp_dir/result.mp4" ]; then
  mv "$tmp_dir/result.mp4" "${BASENAME}_ppt.mp4"
elif [ -f "${BASENAME}/result.mp4" ]; then
  mv "${BASENAME}/result.mp4" "${BASENAME}_ppt.mp4"
elif [ -f "result.mp4" ]; then
  mv "result.mp4" "${BASENAME}_ppt.mp4"
fi

# Always produce a 16:9 PowerPoint-compatible video using ffmpeg
ffmpeg -y -i "${BASENAME}_ppt.mp4" -vf "scale=w=1920:h=1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -an -movflags +faststart -preset slow "${BASENAME}_ppt_16_9.mp4"

# Verification
if [ -f "${BASENAME}_ppt_16_9.mp4" ] && [ -s "${BASENAME}_ppt_16_9.mp4" ]; then
  echo -e "\n\033[1;32m=== Conversion Complete ===\033[0m"
  echo -e "Output file: \033[1;35m${BASENAME}_ppt_16_9.mp4\033[0m"
  # Verify dimensions and aspect ratio
  echo -n "Verifying format: "
  ffprobe_out=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,display_aspect_ratio -of csv=s=x:p=0 "${BASENAME}_ppt_16_9.mp4")
  echo "$ffprobe_out"
  width=$(echo "$ffprobe_out" | cut -d'x' -f1)
  height=$(echo "$ffprobe_out" | cut -d'x' -f2)
  dar=$(echo "$ffprobe_out" | cut -d'x' -f3)
  if [ "$width" = "1920" ] && [ "$height" = "1080" ]; then
    echo -e "\033[1;32mConfirmed: Output is 1920x1080 (16:9)\033[0m"
  else
    echo -e "\033[1;33mWarning: Output is $width x $height (DAR $dar), not exactly 1920x1080 (16:9)\033[0m"
  fi
  # Clean up intermediary files
  if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
    echo "Deleting temp directory: $tmp_dir"
    rm -rf -- "$tmp_dir"
    if [ -d "$tmp_dir" ]; then
      echo -e "\033[1;33mWarning: Temp directory $tmp_dir could not be deleted.\033[0m"
    fi
  fi
  [ -f "${BASENAME}_ppt.mp4" ] && rm -f "${BASENAME}_ppt.mp4"
  [ -f "${BASENAME}/result.mp4" ] && rm -f "${BASENAME}/result.mp4"
else
  echo -e "\n\033[1;31m=== Conversion Failed ===\033[0m"
  echo "No output file created. Check logs."
  exit 1
fi

# Final instructions
echo -e "\n\033[1;33mInsert into PowerPoint:\033[0m"
echo "1. Go to Insert > Video > Video on My PC"
echo "2. Select '${BASENAME}_ppt_16_9.mp4'"
echo "3. Right-click video → Playback → Set to:"
echo "   • Start: Automatically"
echo "   • Loop until Stopped"
