#!/data/data/com.termux/files/usr/bin/bash
# Ends the i3 session and the X server (Super+Shift+E), releases the wake lock.

DISPLAY=${DISPLAY:-:0} i3-msg -q exit 2>/dev/null
pkill -f com.termux.x11 2>/dev/null
pulseaudio --kill 2>/dev/null
termux-wake-unlock
