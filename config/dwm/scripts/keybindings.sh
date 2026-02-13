#!/bin/sh
#
# Display dwm keybindings in rofi
#

rofi -dmenu -i -p "Keybindings" -no-custom << 'EOF'
Super+p             Rofi launcher
Super+Shift+p       dmenu
Super+Shift+Return  Terminal (ghostty)
Super+Shift+w       Random wallpaper
Super+Shift+c       Close window
Super+Shift+q       Quit dwm
Super+b             Toggle bar
Super+j             Focus next window
Super+k             Focus prev window
Super+h             Shrink master
Super+l             Expand master
Super+i             Add to master
Super+d             Remove from master
Super+Return        Promote to master
Super+Tab           Previous tag
Super+t             Tiled layout
Super+f             Floating layout
Super+m             Monocle layout
Super+Space         Toggle layout
Super+Shift+Space   Toggle floating
Super+1-9           Switch to tag
Super+Shift+1-9     Move window to tag
Super+0             View all tags
Super+Shift+0       Tag window to all
Super+,             Focus prev monitor
Super+.             Focus next monitor
Super+Shift+,       Move to prev monitor
Super+Shift+.       Move to next monitor
Super+Shift+h       Show keybindings
EOF
