#!/bin/bash

# Shared core functions for .cast to PowerPoint-compatible 16:9 MP4 conversion

# Usage:
#   source ./cast2video_core.sh
#   check_dependency <tool>
#   convert_cast_to_video <input_cast> <geometry> <scale_factor>
#   convert_to_16_9 <basename>
#   verify_and_cleanup <basename> <tmp_dir>

check_dependency() {
    if ! command -v "$1" &> /dev/null; then
        echo "ERROR: $1 not installed. Please install it first."
        exit 1
    fi
}

convert_cast_to_video() {
    local input_cast="$1"
    local geometry="$2"
    local scale_factor="$3"
    local basename="${input_cast%.cast}"

    echo -e "\n\033[1;34m=== Converting .cast to MP4 ===\033[0m"
    echo "Running: docker run --rm -v \"$PWD:/data\" beer5215/asciicast2mp4 -S $scale_factor -w \"${geometry%x*}\" -h \"${geometry#*x}\" \"$input_cast\""
    docker run --rm -v "$PWD:/data" beer5215/asciicast2mp4 -S "$scale_factor" \
      -w "${geometry%x*}" -h "${geometry#*x}" "$input_cast"

    # Move result.mp4 if found
    if [ -f "$tmp_dir/result.mp4" ]; then
      mv "$tmp_dir/result.mp4" "${basename}_ppt.mp4"
    elif [ -f "${basename}/result.mp4" ]; then
      mv "${basename}/result.mp4" "${basename}_ppt.mp4"
    elif [ -f "result.mp4" ]; then
      mv "result.mp4" "${basename}_ppt.mp4"
    fi
}

convert_to_16_9() {
    local basename="$1"
    local output_res="${2:-1920x1080}"
    local output_file="${3:-${basename}_ppt_16_9.mp4}"
    local width="${output_res%x*}"
    local height="${output_res#*x}"
    ffmpeg -y -i "${basename}_ppt.mp4" -vf "scale=w=${width}:h=${height}:force_original_aspect_ratio=decrease,pad=${width}:${height}:(ow-iw)/2:(oh-ih)/2" \
      -c:v libx264 -profile:v high -level 4.0 -pix_fmt yuv420p -an -movflags +faststart -preset slow "$output_file"
}

verify_and_cleanup() {
    local basename="$1"
    local tmp_dir="$2"
    local output_file="${3:-${basename}_ppt_16_9.mp4}"
    local expected_width="${4:-1920}"
    local expected_height="${5:-1080}"
    if [ -f "$output_file" ] && [ -s "$output_file" ]; then
      echo -e "\n\033[1;32m=== Conversion Complete ===\033[0m"
      echo -e "Output file: \033[1;35m${output_file}\033[0m"
      # Verify dimensions and aspect ratio
      echo -n "Verifying format: "
      ffprobe_out=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height,display_aspect_ratio -of csv=s=x:p=0 "$output_file")
      echo "$ffprobe_out"
      width=$(echo "$ffprobe_out" | cut -d'x' -f1)
      height=$(echo "$ffprobe_out" | cut -d'x' -f2)
      dar=$(echo "$ffprobe_out" | cut -d'x' -f3)
      if [ "$width" = "$expected_width" ] && [ "$height" = "$expected_height" ]; then
        echo -e "\033[1;32mConfirmed: Output is ${expected_width}x${expected_height} (16:9)\033[0m"
      else
        echo -e "\033[1;33mWarning: Output is $width x $height (DAR $dar), not exactly ${expected_width}x${expected_height} (16:9)\033[0m"
      fi
      # Clean up intermediary files
      if [ -n "$tmp_dir" ] && [ -d "$tmp_dir" ]; then
        echo "Deleting temp directory: $tmp_dir"
        rm -rf -- "$tmp_dir"
        if [ -d "$tmp_dir" ]; then
          echo -e "\033[1;33mWarning: Temp directory $tmp_dir could not be deleted.\033[0m"
        fi
      fi
      [ -f "${basename}_ppt.mp4" ] && rm -f "${basename}_ppt.mp4"
      [ -f "${basename}/result.mp4" ] && rm -f "${basename}/result.mp4"
    else
      echo -e "\n\033[1;31m=== Conversion Failed ===\033[0m"
      echo "No output file created. Check logs."
      exit 1
    fi
}
