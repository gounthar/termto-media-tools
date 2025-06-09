#!/bin/bash

# Usage: wrap_long_lines.sh [--no-wrap] [--length N] inputfile
# If --no-wrap is provided, the script outputs the file unchanged.
# --length N (or -l N) sets the maximum line length for wrapping (default: 80).
# Otherwise, lines longer than the specified length are wrapped with '\' as in bash.

set -e

NO_WRAP=0
MAXLEN=80

# Parse options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-wrap)
            NO_WRAP=1
            shift
            ;;
        --length|-l)
            if [[ -n "$2" && "$2" =~ ^[0-9]+$ ]]; then
                MAXLEN="$2"
                shift 2
            else
                echo "Error: --length requires a numeric argument."
                exit 1
            fi
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [--no-wrap] [--length N] inputfile"
    exit 1
fi

INPUT="$1"

if [[ ! -f "$INPUT" ]]; then
    echo "File not found: $INPUT"
    exit 1
fi

if [[ $NO_WRAP -eq 1 ]]; then
    cat "$INPUT"
    exit 0
fi

# Function to wrap a single line
wrap_line() {
    local line="$1"
    local maxlen="$2"
    # Get leading whitespace for indentation
    local indent
    indent="$(echo "$line" | grep -o '^[[:space:]]*')"
    local extra_indent="    "  # 4 spaces
    local first=1
    while [[ ${#line} -gt $maxlen ]]; do
        # Find the last space within the first $maxlen characters
        local cutpos=$(echo "${line:0:$maxlen}" | awk '
            {
                last = 0
                for (i = 1; i <= length($0); i++) {
                    if (substr($0, i, 1) == " ") last = i
                }
                print last
            }
        ')
        if [[ $cutpos -eq 0 ]]; then
            # No space found, hard cut at maxlen
            cutpos=$maxlen
        fi
        # Print the part up to cutpos, add backslash
        if [[ $first -eq 1 ]]; then
            echo "${line:0:$cutpos}\\"
            first=0
        else
            echo "${indent}${extra_indent}${line:0:$cutpos}\\"
        fi
        # Remove the part up to cutpos and leading spaces
        line="${line:$cutpos}"
        line="${line#"${line%%[! ]*}"}"
    done
    if [[ $first -eq 1 ]]; then
        echo "$line"
    else
        echo "${indent}${extra_indent}$line"
    fi
}

# Read and process each line
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ ${#line} -le $MAXLEN ]]; then
        echo "$line"
    else
        wrap_line "$line" "$MAXLEN"
    fi
done < "$INPUT"
