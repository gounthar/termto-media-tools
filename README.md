# termto-media-tools

This repository contains scripts and documentation for converting terminal recordings into video formats compatible with PowerPoint presentations. The project includes tools for creating both standard and 4K resolution videos from terminal sessions.

## Overview

The project consists of the following components:

### Scripts

- **scripts/termtopptvideo.sh**: A script that converts terminal recordings into 16:9 MP4 videos suitable for PowerPoint. It handles recording, dependency checks, and video conversion using Docker. The script also verifies the output format and provides instructions for inserting the video into PowerPoint.

- **scripts/termtopptvideo_4k.sh**: Similar to the standard script, this one specifically creates 4K resolution videos (3840x2160). It follows the same process of recording, checking dependencies, and using Docker for conversion, ensuring the output is suitable for high-resolution presentations.

- **scripts/speedup_segment.sh**: Speeds up a specific segment of a video file without losing quality. The script splits the input video into three segments (before, during, and after the target segment), speeds up the middle segment (handling both video and audio), and then concatenates the segments back together.  
  **Usage:**  
  `speedup_segment.sh input.mp4 output.mp4 speed_factor start_time end_time`  
  **Example:**  
  `speedup_segment.sh input.mp4 output.mp4 2.0 00:01:00 00:02:00`  
  This will double the speed of the segment from 1:00 to 2:00 in the input video and produce the result in output.mp4.

### Documentation

- **docs/Converting Terminal Recordings for PowerPoint_ Vid.md**: This document discusses the challenges of converting terminal recordings to video formats for PowerPoint, outlines the current state of SVG support in PowerPoint, and recommends various video conversion solutions.

- **docs/Step-by-Step Guide_ Creating a High-Quality 16_9 T.md**: A detailed guide on recording terminal sessions with `termtosvg`, converting them to high-resolution MP4 videos, and ensuring compatibility with PowerPoint.

## Usage

To use the scripts, ensure you have the necessary dependencies installed, including Docker and `termtosvg`. Follow the instructions in the respective script files for recording terminal sessions and converting them to video formats.

For detailed guidance on the conversion process and best practices for PowerPoint integration, refer to the documentation in the `docs` directory.

## Contribution

Contributions to improve the scripts and documentation are welcome. Please submit a pull request or open an issue for any suggestions or enhancements.
