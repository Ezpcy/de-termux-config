#!/data/data/com.termux/files/usr/bin/bash
# Volume keys: the Hypr volume.sh rewritten for pactl (PulseAudio on Termux).
#   volume.sh raise|lower|mute|micmute
case "$1" in
    raise)   pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    lower)   pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    mute)    pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    micmute) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
esac

VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -o '[0-9]*%' | head -1 | tr -d %)
VOL=${VOL:-0}
# Keep the progress bar within 100 even when over-amplified.
BAR=$((VOL > 100 ? 100 : VOL))

if pactl get-sink-mute @DEFAULT_SINK@ | grep -q yes; then
    notify-send -h string:x-canonical-private-synchronous:volume \
                -h int:value:0 \
                -t 1500 \
                "Volume" "Muted"
else
    notify-send -h string:x-canonical-private-synchronous:volume \
                -h int:value:"$BAR" \
                -t 1500 \
                "Volume" "$VOL%"
fi
# x-canonical-private-synchronous:volume replaces the previous toast instead
# of stacking; int:value makes dunst draw a progress bar.
