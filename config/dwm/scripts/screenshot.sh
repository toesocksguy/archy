#!/usr/bin/env bash
#
# screenshot.sh — take a screenshot, prompt to save/copy, notify.
#
# Usage:
#   screenshot.sh          # region select
#   screenshot.sh --full   # fullscreen
#
# Saves to ~/Pictures/screenshots/ with a timestamp filename.

SAVE_DIR="$HOME/Pictures/screenshots"
mkdir -p "$SAVE_DIR"

# Capture to a temp file first so the rofi prompt doesn't appear in the shot
tmpfile=$(mktemp /tmp/screenshot-XXXXXX.png)
trap 'rm -f "$tmpfile"' EXIT

if [[ "$1" == "--full" ]]; then
    maim "$tmpfile"
else
    maim -s "$tmpfile"
fi

# Bail if maim failed or was cancelled (e.g. user pressed Escape during select)
[[ $? -eq 0 && -f "$tmpfile" ]] || exit 0

# Prompt for action
action=$(printf "Save & Copy\nSave only\nCopy only\nDiscard" \
    | rofi -dmenu -p "Screenshot" -theme-str 'window {width: 300px;}')

[[ -z "$action" ]] && exit 0

outfile="$SAVE_DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$action" in
    "Save & Copy")
        cp "$tmpfile" "$outfile"
        xclip -selection clipboard -t image/png -i "$outfile"
        notify-send "Screenshot" "Saved to $outfile"
        ;;
    "Save only")
        cp "$tmpfile" "$outfile"
        notify-send "Screenshot" "Saved to $outfile"
        ;;
    "Copy only")
        xclip -selection clipboard -t image/png -i "$tmpfile"
        notify-send "Screenshot" "Copied to clipboard"
        ;;
    "Discard")
        ;;
esac
