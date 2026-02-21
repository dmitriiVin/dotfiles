#!/usr/bin/env bash
# Выбор стиля Waybar

IFS=$'\n\t'

# Пути
waybar_styles="$HOME/.config/waybar/style"
waybar_style="$HOME/.config/waybar/style.css"
SCRIPTSDIR="$HOME/.config/hypr/scripts"
rofi_config="$HOME/.config/rofi/config-waybar-style.rasi"
msg='Некоторые стили Waybar могут отображаться некорректно с отдельными макетами'

# Применяем выбранный стиль
apply_style() {
    ln -sf "$waybar_styles/$1.css" "$waybar_style"
    "${SCRIPTSDIR}/Refresh.sh" &
}

main() {
    # Текущий активный стиль (по symlink)
    current_target=$(readlink -f "$waybar_style")
    current_name=$(basename "$current_target" .css)

    # Список доступных стилей
    mapfile -t options < <(
        find -L "$waybar_styles" -maxdepth 1 -type f -name '*.css' \
            -exec basename {} .css \; \
            | sort
    )

    # Отмечаем активный стиль
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

    [[ -z "$choice" ]] && { echo "Стиль не выбран. Выход."; exit 0; }

    # Убираем маркер и применяем
    choice=${choice#"$MARKER "}
    apply_style "$choice"
}

# Если rofi уже запущен, перезапускаем его
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
    #exit 0
fi

main
