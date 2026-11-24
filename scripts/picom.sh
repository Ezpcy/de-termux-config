#!/data/data/com.termux/files/usr/bin/bash
# Starts picom for the i3 session.
#
# Backend: xrender by default. On Termux:X11 the GL backend goes through zink,
# which can't create a Vulkan swapchain there: picom then trips an assertion
# and dies after a few seconds (and with MESA_VK_WSI_DEBUG=sw it draws a
# black screen). Apps themselves still render on the GPU.
# Try GL anyway with:  PICOM_BACKEND=glx ~/.config/i3/scripts/picom.sh

conf=~/.config/i3/picom.conf
backend=${PICOM_BACKEND:-xrender}

pkill -x picom
while pgrep -x picom >/dev/null; do sleep 0.1; done

exec env -u MESA_VK_WSI_DEBUG picom --config "$conf" --backend "$backend"
