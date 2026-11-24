#!/data/data/com.termux/files/usr/bin/bash
# Starts the i3 desktop in Termux:X11 (symlinked to ~/start-desktop.sh).

# Keep the CPU awake while the desktop runs (stop-desktop.sh releases it)
termux-wake-lock

LOG="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/termux-x11.log"
SOCKET="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/.X11-unix/X0"

# Clear out whatever the previous session left behind (also one that died
# without being stopped), keeping PulseAudio
"$(dirname "$(readlink -f "$0")")/stop-desktop.sh" --restart

export XDG_RUNTIME_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
# Icon/theme lookup (dunst, rofi, GTK) under $PREFIX instead of /usr
export XDG_DATA_DIRS="$PREFIX/share:$HOME/.local/share"
export XDG_CONFIG_DIRS="$PREFIX/etc/xdg"

# Sound: PulseAudio accepting local connections, for apps in the desktop.
# Started without DISPLAY/D-Bus: otherwise it runs `dbus-launch --autolaunch`
# against :0, which hangs when a dead session is still around, and
# `pulseaudio --start` never returns.
if ! pulseaudio --check 2>/dev/null; then
  pkill -x pulseaudio 2>/dev/null
  rm -rf "$XDG_RUNTIME_DIR/pulse"
  env -u DISPLAY -u DBUS_SESSION_BUS_ADDRESS timeout 15 \
    pulseaudio --start --exit-idle-time=-1 \
      --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" ||
    echo "PulseAudio didn't start, continuing without sound" >&2
fi
export PULSE_SERVER=127.0.0.1

export DISPLAY=:0

# GPU: OpenGL through Zink on top of Turnip (Adreno Vulkan).
# glxinfo -B | grep renderer shows "zink"/"Turnip" when this works and
# "llvmpipe" when Mesa fell back to software.
# Only on Qualcomm Adreno (Turnip only supports those): forcing zink on
# another GPU would break GL instead of falling back to llvmpipe.
if [[ $(getprop ro.hardware.vulkan 2>/dev/null) == adreno* ]]; then
  export MESA_LOADER_DRIVER_OVERRIDE=zink
  export TU_DEBUG=noconform
  export GALLIUM_DRIVER=zink
  # termux-x11 has no usable DRI3 swapchain for Turnip: without this, zink
  # can't create a swapchain and GL windows (kitty, picom) stay black.
  # The software WSI copies frames instead and still renders on the GPU.
  export MESA_VK_WSI_DEBUG=sw
fi

# GTK/Qt apps: dark, X11
export GTK_THEME=Adwaita:dark
export QT_QPA_PLATFORM=xcb
export XCURSOR_SIZE=20

# X server on :0, running i3 inside a D-Bus session
termux-x11 :0 -xstartup "dbus-launch --exit-with-session i3 -c $HOME/.config/i3/config" \
  >"$LOG" 2>&1 &

# Wait for the server before switching to the app (it says "not connected"
# when opened before the server is up)
for _ in {1..100}; do
  [[ -S $SOCKET ]] && break
  sleep 0.1
done
if [[ ! -S $SOCKET ]]; then
  echo "X server didn't come up within 10s. Log: $LOG" >&2
  tail -n 20 "$LOG" >&2
  exit 1
fi

# Switch to the Termux:X11 app
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
