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

# 16:9 padding for 1280x720 output (adjust as needed)
PAD_HORIZ=340
PAD_VERT=160

# Theme and font settings
THEME="GitHub"
BACKGROUND="#ffffff"
FONT="DejaVu Sans Mono"

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
    echo "Warning: Could not detect language from extension '$EXT'. Defaulting to plaintext. You can specify a language as the second argument."
    LANG="plaintext"
  fi
fi

# Build silicon command
CMD=(silicon "$INPUT" -o "$OUT" --theme "$THEME" --background "$BACKGROUND" --no-window-controls --pad-horiz "$PAD_HORIZ" --pad-vert "$PAD_VERT" --font "$FONT")
if [ -n "$LANG" ]; then
  CMD+=(-l "$LANG")
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}"
echo "Image generated: $OUT"
