# termto-media-tools
## flatten_timestamps.sh

A shell script to set the timestamps of all events in a given range to a single timestamp in an asciinema `.cast` file.

### Purpose

Given a `.cast` file (asciinema format: first line is a JSON object header, subsequent lines are JSON arrays for events), a start timestamp, and an end timestamp, the script will set the timestamp of all event lines between these two values (inclusive) to the start timestamp. All other lines are left unchanged.

### Usage

```sh
./scripts/flatten_timestamps.sh input.cast start_timestamp end_timestamp output.cast
```

- `input.cast`:         Input .cast file (asciinema format)
- `start_timestamp`:    Start of range (inclusive)
- `end_timestamp`:      End of range (inclusive)
- `output.cast`:        Output file path

### Example

```sh
./scripts/flatten_timestamps.sh mysession.cast 0.000000 23.844826 output.cast
```
This will set the timestamp of all event lines between `0.000000` and `23.844826` (inclusive) to `0.000000`.

### Notes

- The script will attempt to install `gawk` automatically if it is not present, using the most common package managers (`apt-get`, `dnf`, `yum`, `pacman`, `brew`, `choco`). If installation fails, you will be prompted to install `gawk` manually.
- The script is compatible with standard asciinema `.cast` files (header line as JSON object, event lines as JSON arrays).

## shorten_gap.sh

A shell script to adjust the timing of events in an asciinema `.cast` file by shortening the gap between a specified event and its previous event.

### Purpose

Given a `.cast` file (asciinema format: first line is a JSON object header, subsequent lines are JSON arrays for events), a target timestamp, and an output file, the script will reduce the time gap between the specified event and the previous event to the next half second (by default), or to a custom gap if specified. All subsequent events are shifted accordingly.

### Usage

```sh
./scripts/shorten_gap.sh input.cast target_timestamp output.cast [gap]
```

- `input.cast`:         Input .cast file (asciinema format)
- `target_timestamp`:   Timestamp to adjust (e.g., 231.281972)
- `output.cast`:        Output file path
- `gap` (optional):     Custom gap in seconds (default: "next half second")

### How the "next half second" works

If the previous event's timestamp is, for example, `37.935336`, the next half second is `38.0` (rounded up to the next 0.5s). The script will set the gap to this value unless a custom gap is provided.

### Example

```sh
./scripts/shorten_gap.sh mysession.cast 231.356032 output.cast
```
This will set the gap between the event at `231.356032` and its previous event to the next half second.

To use a custom gap (e.g., 0.7 seconds):

```sh
./scripts/shorten_gap.sh mysession.cast 231.356032 output.cast 0.7
```

### Notes

- The script will attempt to install `gawk` automatically if it is not present, using the most common package managers (`apt-get`, `dnf`, `yum`, `pacman`, `brew`, `choco`). If installation fails, you will be prompted to install `gawk` manually.
- The script is compatible with standard asciinema `.cast` files (header line as JSON object, event lines as JSON arrays).

This repository contains scripts and documentation for converting terminal recordings into video formats compatible with PowerPoint presentations. The project includes tools for creating both standard and 4K resolution videos from terminal sessions.

## Overview

The project consists of the following components:

### Scripts

- **scripts/trim_cast.sh**: Manipulates asciinema `.cast` files by removing all events with timestamps in a specified range and rebasing the remaining timestamps.  
  **Usage:**  
  `trim_cast.sh input.cast start_time end_time output.cast`  
  - Removes all events with timestamps `>= start_time` and `< end_time`.
  - Keeps all other events.
  - Rebases timestamps so the first kept event is at 0.
  - Preserves the header unchanged.
  - Outputs each event as a single-line JSON array (asciinema v2 format).
  - Handles Windows line endings and whitespace robustly.
  - Requires `jq` to be installed.
  **Example:**  
  `trim_cast.sh terminal_recording.cast 0.0 14.09051 trimmed.cast`  
  This will remove all events from 0.0 up to (but not including) 14.09051 seconds, rebase the remaining events, and write the result to `trimmed.cast`.

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
