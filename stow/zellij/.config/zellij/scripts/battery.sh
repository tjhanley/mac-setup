#!/bin/sh
batt_info=$(pmset -g batt)
pct=$(echo "$batt_info" | awk '/InternalBattery/{gsub(/;/,"");print $3+0}')
charging=$(echo "$batt_info" | grep -q 'AC Power' && echo 1 || echo 0)

if [ "$charging" = "1" ]; then
    icon="󰂄"
elif [ "$pct" -ge 90 ]; then
    icon="󰁹"
elif [ "$pct" -ge 80 ]; then
    icon="󰂂"
elif [ "$pct" -ge 70 ]; then
    icon="󰂁"
elif [ "$pct" -ge 60 ]; then
    icon="󰂀"
elif [ "$pct" -ge 50 ]; then
    icon="󰁿"
elif [ "$pct" -ge 40 ]; then
    icon="󰁾"
elif [ "$pct" -ge 30 ]; then
    icon="󰁽"
elif [ "$pct" -ge 20 ]; then
    icon="󰁼"
elif [ "$pct" -ge 10 ]; then
    icon="󰁻"
else
    icon="󰂎"
fi

case "${1:-pct}" in
    icon) printf "%s" "$icon" ;;
    *)    printf "%d%%" "$pct" ;;
esac
