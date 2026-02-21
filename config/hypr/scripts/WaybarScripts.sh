#!/usr/bin/env bash
# Скрипт для модулей Waybar: запуск терминала/файлового менеджера

# Путь к пользовательскому конфигу
config_file=$HOME/.config/hypr/configs/Defaults.conf

# Проверяем наличие файла конфигурации
if [[ ! -f "$config_file" ]]; then
    echo "Ошибка: не найден файл конфигурации."
    exit 1
fi

# Подготавливаем переменные для source/eval
config_content=$(sed 's/\$//g' "$config_file" | sed 's/ = /=/')

# Подгружаем содержимое
eval "$config_content"

# Проверяем наличие терминала в переменной $term
if [[ -z "$term" ]]; then
    echo "Ошибка: в конфиге не задана переменная \$term."
    exit 1
fi

# Выполняем действие по аргументу
launch_files() {
    if [[ -z "$files" ]]; then
        notify-send -u low -i "$HOME/.config/swaync/images/error.png" "Waybar: файлы" "Задайте \$files в configs/Defaults.conf или установите файловый менеджер."
        return 1
    fi
    eval "$files &"
}

if [[ "$1" == "--btop" ]]; then
    $term --title btop sh -c 'btop'
elif [[ "$1" == "--nvtop" ]]; then
    $term --title nvtop sh -c 'nvtop'
elif [[ "$1" == "--nmtui" ]]; then
    $term nmtui
elif [[ "$1" == "--term" ]]; then
    $term &
elif [[ "$1" == "--files" ]]; then
    launch_files
else
    echo "Использование: $0 [--btop | --nvtop | --nmtui | --term | --files]"
    echo "--btop   : открыть btop в терминале"
    echo "--nvtop  : открыть nvtop в терминале"
    echo "--nmtui  : открыть nmtui в терминале"
    echo "--term   : запустить терминал"
    echo "--files  : запустить файловый менеджер"
fi
