#!/data/data/com.termux/files/usr/bin/bash
# Starts the i3 desktop in Termux:X11 (symlinked to ~/start-desktop.sh).

# Keep the CPU awake while the desktop runs (stop-desktop.sh releases it)
termux-wake-lock

# Kill an old X server (and the session inside it) if one is still running
pkill -f com.termux.x11 2>/dev/null
sleep 0.5

export DISPLAY=:0
export XDG_RUNTIME_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
# Icon/theme lookup (dunst, rofi, GTK) under $PREFIX instead of /usr
export XDG_DATA_DIRS="$PREFIX/share:$HOME/.local/share"
export XDG_CONFIG_DIRS="$PREFIX/etc/xdg"

# Sound: PulseAudio accepting local connections, for apps in the desktop
if ! pulseaudio --check 2>/dev/null; then
  pulseaudio --start --exit-idle-time=-1 \
    --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1"
fi
export PULSE_SERVER=127.0.0.1

# GPU: OpenGL through Zink on top of Turnip (Adreno Vulkan).
# glxinfo -B | grep renderer shows "zink"/"Turnip" when this works and
# "llvmpipe" when Mesa fell back to software (picom.sh then uses xrender).
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export GALLIUM_DRIVER=zink
# termux-x11 has no usable DRI3 swapchain for Turnip: without this, zink
# can't create a swapchain and GL windows (kitty, picom) stay black.
# The software WSI copies frames instead and still renders on the GPU.
export MESA_VK_WSI_DEBUG=sw

# GTK/Qt apps: dark, X11
export GTK_THEME=Adwaita:dark
export QT_QPA_PLATFORM=xcb
export XCURSOR_SIZE=20

# X server on :0, running i3 inside a D-Bus session
termux-x11 :0 -xstartup "dbus-launch --exit-with-session i3 -c $HOME/.config/i3/config" \
  >"$XDG_RUNTIME_DIR/termux-x11.log" 2>&1 &

sleep 1
# Switch to the Termux:X11 app
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
