#!/data/data/com.termux/files/usr/bin/bash
# Ends the i3 session and the X server (Super+Shift+E), releases the wake lock.
#
#   stop-desktop.sh            full stop, PulseAudio too
#   stop-desktop.sh --restart  clear out the previous session only; used by
#                              start-desktop.sh, keeps PulseAudio running
#
# Also cleans up after a session that died without being stopped (Termux:X11
# app closed, X server killed by Android): such leftovers hang on the dead X
# connection, ignore SIGTERM, and used to keep the next start from working.

restart=false
[[ ${1:-} == --restart ]] && restart=true

DISPLAY_NUM=0
X11_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

# stop PGREP_ARGS...: SIGTERM, wait up to 2s, then SIGKILL what's left.
stop() {
  local pids
  pids=$(pgrep "$@") || return 0
  kill $pids 2>/dev/null
  for _ in {1..20}; do
    pids=$(pgrep "$@") || return 0
    sleep 0.1
  done
  kill -9 $pids 2>/dev/null
}

# A clean exit first, while the X server may still be up
DISPLAY=:$DISPLAY_NUM timeout 3 i3-msg -q exit >/dev/null 2>&1

stop -x i3
stop -x picom
stop -x polybar
stop -x dunst
stop -f '^dbus-launch'                   # session bus, and pulseaudio's autolaunch
stop -f '^dbus-daemon .*--session'
stop -f '^termux-x11 com\.termux\.x11 '  # the X server (all displays)

# A stale lock/socket would make the next server refuse to start
rm -f "$X11_DIR/.X$DISPLAY_NUM-lock" "$X11_DIR/.X11-unix/X$DISPLAY_NUM"

if ! $restart; then
  pulseaudio --kill >/dev/null 2>&1
  stop -x pulseaudio
  termux-wake-unlock
fi
exit 0
