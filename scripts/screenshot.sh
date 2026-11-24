#!/data/data/com.termux/files/usr/bin/bash
# Screenshots with maim (grim/slurp/hyprshot replacement).
#   screenshot.sh region   select an area   (Super+Shift+S)
#   screenshot.sh window   focused window   (Super+Print)
#   screenshot.sh screen   whole screen     (Super+Shift+Print)
# The image goes to the X clipboard and is also saved, because Termux:X11
# only shares text with the Android clipboard.

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "${1:-region}" in
  region) maim -s -u -b 1 -c 0.16,0.66,0.62 "$file" || exit 0 ;; # cancelled: keep the clipboard
  window) maim -u -i "$(xdotool getactivewindow)" "$file" || exit 1 ;;
  screen) maim -u "$file" || exit 1 ;;
  *) echo "usage: $0 region|window|screen" >&2; exit 2 ;;
esac

xclip -selection clipboard -t image/png -i "$file"
notify-send -a Screenshot -h string:x-canonical-private-synchronous:screenshot \
  -i "$file" -t 3000 "Screenshot copied" "${file/#$HOME/\~}"
