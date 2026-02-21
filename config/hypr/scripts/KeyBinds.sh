#!/usr/bin/env bash
# Поиск горячих клавиш через rofi (поддержка bindd-описаний)

# Закрываем yad, чтобы не мешал поиску биндов
pkill yad || true

# Если rofi уже открыт, перезапускаем его
if pidof rofi > /dev/null; then
  pkill rofi
fi

# Файлы с биндами
keybinds_conf="$HOME/.config/hypr/configs/Keybinds.conf"
laptop_conf="$HOME/.config/hypr/configs/Laptops.conf"
rofi_theme="$HOME/.config/rofi/config-keybinds.rasi"
msg='☢️ Подсказка: клик и ENTER только для просмотра, команды не запускаются'

# Собираем bind-строки из доступных файлов
files=("$keybinds_conf")
[[ -f "$laptop_conf" ]] && files+=("$laptop_conf")

# Парсим бинды Python-скриптом (быстрее и точнее для override)
display_keybinds=$("$HOME/.config/hypr/scripts/keybinds_parser.py" "${files[@]}")

# Проверяем файл с подсказками от parser (если есть)
if [[ -f "/tmp/hypr_keybind_suggestions_file" ]]; then
  suggestions_file=$(cat "/tmp/hypr_keybind_suggestions_file")
  rm "/tmp/hypr_keybind_suggestions_file"
  if [[ -n "$suggestions_file" && -f "$suggestions_file" ]]; then
     count=$(wc -l < "$suggestions_file")
     msg="$msg | Внимание: override без unbind: $count (список: $suggestions_file)"
  fi
fi

# Показываем бинды в rofi
printf '%s\n' "$display_keybinds" | rofi -dmenu -i -config "$rofi_theme" -mesg "$msg"
