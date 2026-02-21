#!/usr/bin/env bash
# Обновление rofi/wallust/swaync без перезапуска Waybar

SCRIPTSDIR=$HOME/.config/hypr/scripts
scriptsDir=$HOME/.config/hypr/scripts

# Define file_exists function
file_exists() {
    if [ -e "$1" ]; then
        return 0  # File exists
    else
        return 1  # File does not exist
    fi
}

# Kill already running processes
_ps=(rofi)
for _prs in "${_ps[@]}"; do
    if pidof "${_prs}" >/dev/null; then
        pkill "${_prs}"
    fi
done

# quit ags & relaunch ags
#ags -q && ags &

# quit quickshell & relaunch quickshell
pkill qs && qs &

# Wallust refresh (synchronous to ensure colors are ready)
${SCRIPTSDIR}/WallustSwww.sh
sleep 0.2

# reload swaync
swaync-client --reload-config

# Повторный запуск RainbowBorders при наличии скрипта
sleep 1
if file_exists "${scriptsDir}/RainbowBorders.sh"; then
    ${scriptsDir}/RainbowBorders.sh &
fi


exit 0
