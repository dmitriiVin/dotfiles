#!/usr/bin/env bash
# Выбор макета Waybar

IFS=$'\n\t'

# Пути
waybar_layouts="$HOME/.config/waybar/configs"
waybar_config="$HOME/.config/waybar/config"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_config="$HOME/.config/rofi/config-waybar-layout.rasi"
msg='Некоторые макеты Waybar могут отображаться некорректно с отдельными стилями'

# Применяем выбранный макет
apply_config() {
    ln -sf "$waybar_layouts/$1" "$waybar_config"
    "${SCRIPTSDIR}/Refresh.sh" &
}

main() {
    # Текущий активный макет
    current_target=$(readlink -f "$waybar_config")
    current_name=$(basename "$current_target")

    # Список доступных макетов
    mapfile -t options < <(
        find -L "$waybar_layouts" -maxdepth 1 -type f -printf '%f\n' | sort
    )

    # Отмечаем активный макет
    default_row=0
    MARKER="👉"
    for i in "${!options[@]}"; do
        if [[ "${options[i]}" == "$current_name" ]]; then
            options[i]="$MARKER ${options[i]}"
            default_row=$i
            break
        fi
    done

    # Показываем выбор в rofi
    choice=$(printf '%s\n' "${options[@]}" \
        | rofi -i -dmenu \
               -config "$rofi_config" \
               -mesg "$msg" \
               -selected-row "$default_row"
    )

    # Если макет не выбран — выходим
    [[ -z "$choice" ]] && { echo "Макет не выбран. Выход."; exit 0; }

    # Убираем маркер перед применением
    choice=${choice#"$MARKER "}

    case "$choice" in
        "no panel")
            pgrep -x "waybar" && pkill waybar || true
            ;;
        *)
            apply_config "$choice"
            ;;
    esac
}

# Если rofi уже запущен, перезапускаем его
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    #exit 0
fi

main
