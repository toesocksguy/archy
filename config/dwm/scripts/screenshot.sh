#!/usr/bin/env bash
#
# screenshot.sh — take a screenshot, save it, copy to clipboard, notify.
#
# Usage:
#   screenshot.sh          # region select
#   screenshot.sh --full   # fullscreen

SAVE_DIR="$HOME/Pictures/screenshots"
mkdir -p "$SAVE_DIR"

outfile="$SAVE_DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

if [[ "$1" == "--full" ]]; then
    maim "$outfile"
else
    maim -s "$outfile"
fi

# Only proceed if maim succeeded (user may have cancelled region select)
if [[ $? -eq 0 && -f "$outfile" ]]; then
    xclip -selection clipboard -t image/png -i "$outfile"
    notify-send "Screenshot" "Saved to $outfile"
fi
