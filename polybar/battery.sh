#!/data/data/com.termux/files/usr/bin/bash
# Battery for polybar via Termux:API (needs the Termux:API app).
# Icon in @accent, @warn below 30%, @danger below 15%.

json=$(timeout 10 termux-battery-status 2>/dev/null) || { echo ""; exit 0; }
pct=$(jq -r '.percentage // empty' <<<"$json")
status=$(jq -r '.status // empty' <<<"$json")
[[ -z $pct ]] && { echo ""; exit 0; }

icons=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
idx=$((pct / 10)); ((idx > 9)) && idx=9
icon=${icons[idx]}
[[ $status == CHARGING || $status == FULL ]] && icon=󰂄

color="#29a99e"
((pct < 30)) && color="#e0af68"
((pct < 15)) && [[ $status != CHARGING ]] && color="#f7768e"

echo "%{F$color}%{T3}$icon%{T-}%{F-} $pct%"
