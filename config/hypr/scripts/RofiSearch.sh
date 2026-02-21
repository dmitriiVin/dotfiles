#!/usr/bin/env bash
# Поиск в интернете через rofi и браузер по умолчанию

# Путь к пользовательскому конфигу
config_file=$HOME/.config/hypr/configs/Defaults.conf
if ! command -v jq >/dev/null 2>&1; then
    notify-send -u low "Rofi Поиск" "Для кодирования URL нужен jq. Установите пакет jq."
    exit 1
fi

# Проверяем наличие файла конфигурации
if [[ ! -f "$config_file" ]]; then
    echo "Ошибка: не найден файл конфигурации."
    exit 1
fi

# Подготавливаем переменные для source/eval
config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')

# Подгружаем содержимое
eval "$config_content"

# Проверяем наличие переменной поиска
if [[ -z "$Search_Engine" ]]; then
    echo "Ошибка: в конфиге не задана переменная \$Search_Engine."
    exit 1
fi

# Тема и сообщение для rofi
rofi_theme="$HOME/.config/rofi/config-search.rasi"
msg='Поиск откроется в браузере по умолчанию'

# Если rofi уже запущен, перезапускаем его
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# Получаем запрос и открываем его в браузере
query=$(printf '' | rofi -dmenu -config "$rofi_theme" -mesg "$msg")

if [[ -z "$query" ]]; then
    exit 0
fi

encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
xdg-open "${Search_Engine}${encoded_query}" >/dev/null 2>&1 &
