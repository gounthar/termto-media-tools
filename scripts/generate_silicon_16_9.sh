#!/bin/bash
# Usage: ./generate_silicon_16_9.sh <input_file> [language]
# Generates a 16:9 code image using silicon, with language auto-detection or override.

set -e

if [ -z "$1" ]; then
  echo "Usage: $0 <input_file> [language]"
  exit 1
fi

INPUT="$1"
LANG="$2"
OUT="${INPUT%.*}.png"

# 16:9 padding for 1920x1080 output (adjust as needed)
PAD_HORIZ=0
PAD_VERT=60

# Theme and font settings
THEME="GitHub"
BACKGROUND="#ffffff"
FONT="DejaVu Sans Mono"
DEFAULT_FONT_SIZE=26
SHORTLINE_FONT_SIZE=40
SHORTLINE_PAD_HORIZ=120
SHORTLINE_PAD_VERT=120

# Detect language from file extension if not provided
if [ -z "$LANG" ]; then
  EXT="${INPUT##*.}"
  # Map common extensions to silicon language names
  declare -A ext_map=(
    [py]=python
    [js]=javascript
    [ts]=typescript
    [sh]=bash
    [rb]=ruby
    [rs]=rust
    [c]=c
    [cpp]=cpp
    [h]=cpp
    [java]=java
    [go]=go
    [php]=php
    [html]=html
    [css]=css
    [json]=json
    [yaml]=yaml
    [yml]=yaml
    [toml]=toml
    [xml]=xml
    [sql]=sql
    [md]=markdown
    [pl]=perl
    [swift]=swift
    [kt]=kotlin
    [dart]=dart
    [hs]=haskell
    [el]=elisp
    [ex]=elixir
    [erl]=erlang
    [scala]=scala
    [lua]=lua
    [bat]=batch
    [ps1]=powershell
    [ini]=ini
    [conf]=nginx
    [dockerfile]=dockerfile
    [makefile]=makefile
    [gitignore]=gitignore
  )
  LANG="${ext_map[$EXT]}"
  if [ -z "$LANG" ]; then
    echo "Warning: Could not detect language from extension '$EXT'. No language will be specified. You can specify a language as the second argument."
    echo "Common supported languages (use as second argument):"
    echo "python, javascript, typescript, bash, ruby, rust, c, cpp, java, go, php, html, css, json, yaml, toml, xml, sql, markdown, perl, swift, kotlin, dart, haskell, elisp, elixir, erlang, scala, lua, batch, powershell, ini, nginx, dockerfile, makefile, gitignore"
    echo "For the full list, see: https://github.com/Aloxaf/silicon#supported-languages"
    # Do not set LANG, so -l is omitted
  fi
fi

# Detect if input is a single short line
LINECOUNT=$(wc -l < "$INPUT")
if [ "$LINECOUNT" -le 1 ]; then
  PAD_HORIZ=40
  PAD_VERT=40
  SCALE_FACTOR=3
  echo "Detected short input ($LINECOUNT line). Will scale up code image by $SCALE_FACTOR x for readability."
else
  SCALE_FACTOR=1
fi

# Build silicon command
CMD=(silicon "$INPUT" -o "$OUT" --theme "$THEME" --background "$BACKGROUND" --no-window-controls --pad-horiz "$PAD_HORIZ" --pad-vert "$PAD_VERT" --font "$FONT")
if [ -n "$LANG" ]; then
  CMD+=(-l "$LANG")
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}"

# For short lines, scale up the code image before compositing
if [ "$SCALE_FACTOR" -gt 1 ]; then
  convert "$OUT" -resize "$((SCALE_FACTOR*100))%" "$OUT"
fi

# Enforce 16:9 aspect ratio (1920x1080) with a blurred background and window controls using ImageMagick

TMP_BG="${OUT%.png}_bg.png"

# 1. For short lines, do NOT upscale the code image; just center it on a 1920x1080 blurred background.
if [ "$LINECOUNT" -le 1 ]; then
  # Create blurred, stretched background
  convert "$OUT" -resize 1920x1080\! -blur 0x20 "$TMP_BG"
  # Center the (now scaled up) code image
  convert "$TMP_BG" "$OUT" -gravity center -composite "$OUT"
else
  # 1. Scale silicon output to 1920px width (preserve aspect ratio)
  convert "$OUT" -resize 1920x "$OUT"

  # 1b. If height > 1080, scale down to fit within 1920x1080 (preserve aspect ratio)
  HEIGHT=$(identify -format "%h" "$OUT")
  if [ "$HEIGHT" -gt 1080 ]; then
    convert "$OUT" -resize 1920x1080 "$OUT"
  fi

  # 2. Create blurred, stretched background
  convert "$OUT" -resize 1920x1080\! -blur 0x20 "$TMP_BG"

  # 3. Overlay the original image, now max 1920x1080, centered
  convert "$TMP_BG" "$OUT" -gravity center -composite "$OUT"
fi

# 4. Draw window controls (red, yellow, green circles at top left)
convert "$OUT" \
  -fill "#ff5f56" -draw "circle 40,30 50,30" \
  -fill "#ffbd2e" -draw "circle 70,30 80,30" \
  -fill "#27c93f" -draw "circle 100,30 110,30" \
  "$OUT"

# 5. Clean up temp file
rm -f "$TMP_BG"

echo "Image generated: $OUT"
