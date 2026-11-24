#!/data/data/com.termux/files/usr/bin/bash
# Terminal wrapper: kitty (as on Hyprland), falling back to xfce4-terminal
# when kitty can't start (it needs OpenGL 3.1; a broken zink/Turnip stack
# makes it exit right away).
#
#   term.sh [--class NAME] [-e CMD ARGS...]

class="" cmd=()
while (($#)); do
  case $1 in
  --class) class=$2; shift 2 ;;
  -e) shift; cmd=("$@"); break ;;
  *) shift ;;
  esac
done

kitty_args=()
[[ -n $class ]] && kitty_args+=(--class "$class")
((${#cmd[@]})) && kitty_args+=("${cmd[@]}")

start=$SECONDS
kitty "${kitty_args[@]}" && exit 0
status=$?

# A failure after a few seconds is the program inside, not kitty itself.
((SECONDS - start > 3)) && exit "$status"

notify-send -a terminal -u low "kitty failed to start" "Using xfce4-terminal instead (no OpenGL 3.1?)"
xfce_args=()
[[ -n $class ]] && xfce_args+=(--title "$class")
((${#cmd[@]})) && xfce_args+=(-x "${cmd[@]}")
exec xfce4-terminal "${xfce_args[@]}"
