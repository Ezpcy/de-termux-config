#!/data/data/com.termux/files/usr/bin/bash
# (Re)starts polybar; run by i3 on every start/restart.
pkill -x polybar
while pgrep -x polybar >/dev/null; do sleep 0.1; done
polybar -c ~/.config/i3/polybar/config.ini -q main \
  >"${XDG_RUNTIME_DIR:-$TMPDIR}/polybar.log" 2>&1 &
disown
