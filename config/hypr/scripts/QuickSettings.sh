#!/usr/bin/env bash
# Меню быстрых настроек Hyprland (SUPER SHIFT E)
# Работа с единым каталогом configs/scripts

# Файл с пользовательскими настройками терминала/редактора
config_file="$HOME/.config/hypr/configs/Defaults.conf"

tmp_config_file=$(mktemp)
sed 's/^\$//g; s/ = /=/g' "$config_file" > "$tmp_config_file"
source "$tmp_config_file"
# ##################################### #

# variables
configs="$HOME/.config/hypr/configs"
rofi_theme="$HOME/.config/rofi/config-edit.rasi"
msg='Выберите действие'
iDIR="$HOME/.config/swaync/images"
scriptsDir="$HOME/.config/hypr/scripts"

# Показ информационных уведомлений
show_info() {
    if [[ -f "$iDIR/info.png" ]]; then
        notify-send -i "$iDIR/info.png" "Инфо" "$1"
    else
        notify-send "Инфо" "$1"
    fi
}
# Включение/выключение RainbowBorders
toggle_rainbow_borders() {
    local rainbow_script="$scriptsDir/RainbowBorders.sh"
    local disabled_sh_bak="${rainbow_script}.bak"           # RainbowBorders.sh.bak
    local disabled_bak_sh="$scriptsDir/RainbowBorders.bak.sh" # RainbowBorders.bak.sh
    local refresh_script="$scriptsDir/Refresh.sh"
    local status=""

    # If both disabled variants exist, keep the newer one to avoid ambiguity
    if [[ -f "$disabled_sh_bak" && -f "$disabled_bak_sh" ]]; then
        if [[ "$disabled_sh_bak" -nt "$disabled_bak_sh" ]]; then
            rm -f "$disabled_bak_sh"
        else
            rm -f "$disabled_sh_bak"
        fi
    fi

    if [[ -f "$rainbow_script" ]]; then
        # Currently enabled -> disable to canonical .sh.bak
        if mv "$rainbow_script" "$disabled_sh_bak"; then
            status="disabled"
            if command -v hyprctl &>/dev/null; then
                hyprctl reload >/dev/null 2>&1 || true
            fi
        fi
    elif [[ -f "$disabled_sh_bak" ]]; then
        # Disabled (.sh.bak) -> enable
        if mv "$disabled_sh_bak" "$rainbow_script"; then
            status="enabled"
        fi
    elif [[ -f "$disabled_bak_sh" ]]; then
        # Disabled (.bak.sh) -> enable (normalize to .sh)
        if mv "$disabled_bak_sh" "$rainbow_script"; then
            status="enabled"
        fi
    else
        show_info "Скрипт RainbowBorders не найден в $scriptsDir (.sh, .sh.bak, .bak.sh)."
        return
    fi

    # Run refresh if available, otherwise apply borders directly
    if [[ -x "$refresh_script" ]]; then
        "$refresh_script" >/dev/null 2>&1 &
    fi

    if [[ -n "$status" ]]; then
        show_info "Rainbow Borders: ${status}."
    fi
}

# Подменю выбора режима RainbowBorders
rainbow_borders_menu() {
    local rainbow_script="$scriptsDir/RainbowBorders.sh"
    local disabled_sh_bak="${rainbow_script}.bak"
    local disabled_bak_sh="$scriptsDir/RainbowBorders.bak.sh"
    local refresh_script="$scriptsDir/Refresh.sh"

    # Determine current mode/status (internal)
    local current="disabled"
    if [[ -f "$rainbow_script" ]]; then
        current=$(grep -E '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null | sed -E 's/^EFFECT_TYPE="?([^"]*)"?/\1/')
        [[ -z "$current" ]] && current="unknown"
    fi

    # Map internal mode to friendly display
    local current_display="$current"
    case "$current" in
        wallust_random) current_display="Цвета Wallust" ;;
        rainbow) current_display="Оригинальная радуга" ;;
        gradient_flow) current_display="Градиентный поток" ;;
        disabled) current_display="Выключено" ;;
    esac


    # Build options and prompt
    local options="Выключить Rainbow Borders\nЦвета Wallust\nОригинальная радуга\nГрадиентный поток"
    local choice
    choice=$(printf "%b" "$options" | rofi -i -dmenu -config "$rofi_theme" -mesg "Rainbow Borders: текущий режим = $current_display")

    [[ -z "$choice" ]] && return

    case "$choice" in
        "Выключить Rainbow Borders")
            if [[ -f "$rainbow_script" ]]; then
                mv "$rainbow_script" "$disabled_sh_bak"
            fi
            current="disabled"
            if command -v hyprctl &>/dev/null; then
                hyprctl reload >/dev/null 2>&1 || true
            fi
            ;;
        "Цвета Wallust"|"Оригинальная радуга"|"Градиентный поток")
            local mode=""
            case "$choice" in
                "Цвета Wallust") mode="wallust_random" ;;
                "Оригинальная радуга") mode="rainbow" ;;
                "Градиентный поток") mode="gradient_flow" ;;
            esac
            # Ensure script is enabled
            if [[ ! -f "$rainbow_script" ]]; then
                if   [[ -f "$disabled_sh_bak" ]]; then
                    mv "$disabled_sh_bak" "$rainbow_script"
                elif [[ -f "$disabled_bak_sh" ]]; then
                    mv "$disabled_bak_sh" "$rainbow_script"
                else
                    show_info "Скрипт RainbowBorders не найден в $scriptsDir."
                    return
                fi
            fi

            # Update EFFECT_TYPE in place; insert if missing
            if grep -q '^EFFECT_TYPE=' "$rainbow_script" 2>/dev/null; then
                sed -i 's/^EFFECT_TYPE=.*/EFFECT_TYPE="'"$mode"'"/' "$rainbow_script"
            else
                if head -n1 "$rainbow_script" | grep -q '^#!'; then
                    sed -i '1a EFFECT_TYPE="'"$mode"'"' "$rainbow_script"
                else
                    sed -i '1i EFFECT_TYPE="'"$mode"'"' "$rainbow_script"
                fi
            fi
            # Set current to chosen mode
            current="$mode"
            ;;
        *)
            return ;;
    esac

    # Run refresh if available
    if [[ -x "$refresh_script" ]]; then
        "$refresh_script" >/dev/null 2>&1 &
    fi

    # Apply mode immediately (in case refresh doesn't trigger it)
    if [[ "$current" != "disabled" && -x "$rainbow_script" ]]; then
        "$rainbow_script" >/dev/null 2>&1 &
    fi

    # No notifications; mode is shown in the menu
}

# Основное меню
menu() {
    cat <<EOF
Правка: приложения по умолчанию
Правка: ENV переменные
Правка: бинды
Правка: автозапуск
Правка: Window Rules
Правка: системные настройки
Правка: декорации
Правка: анимации
Правка: настройки ноутбука
--- УТИЛИТЫ ---
Установить обои SDDM
Тема Kitty
Мониторы (nwg-displays)
Правила рабочих столов (nwg-displays)
GTK настройки (nwg-look)
QT настройки (qt6ct)
QT настройки (qt5ct)
Анимации Hyprland
Профили мониторов
Темы Rofi
Поиск по биндам
Игровой режим
Светлая/тёмная тема
Режим Rainbow Borders
EOF
}

# Обработка выбора
main() {
    choice=$(menu | rofi -i -dmenu -config $rofi_theme -mesg "$msg")
    
    # Обработка выбранного пункта
    case "$choice" in
    	"Правка: приложения по умолчанию") file="$configs/Defaults.conf" ;;
        "Правка: ENV переменные") file="$configs/ENVariables.conf" ;;
        "Правка: бинды") file="$configs/Keybinds.conf" ;;
        "Правка: автозапуск") file="$configs/Startup_Apps.conf" ;;
        "Правка: Window Rules") file="$configs/WindowRules.conf" ;;
        "Правка: системные настройки") file="$configs/SystemSettings.conf" ;;
        "Правка: декорации") file="$configs/Decorations.conf" ;;
        "Правка: анимации") file="$configs/Animations.conf" ;;
        "Правка: настройки ноутбука") file="$configs/Laptops.conf" ;;
        "Установить обои SDDM") $scriptsDir/sddm_wallpaper.sh --normal ;;
        "Тема Kitty") $scriptsDir/Kitty_themes.sh ;;
        "Мониторы (nwg-displays)")
            if ! command -v nwg-displays &>/dev/null; then
                notify-send -i "$iDIR/error.png" "Ошибка" "Установите nwg-displays"
                exit 1
            fi
            nwg-displays ;;
        "Правила рабочих столов (nwg-displays)")
            if ! command -v nwg-displays &>/dev/null; then
                notify-send -i "$iDIR/error.png" "Ошибка" "Установите nwg-displays"
                exit 1
            fi
            nwg-displays ;;
		"GTK настройки (nwg-look)")
            if ! command -v nwg-look &>/dev/null; then
                notify-send -i "$iDIR/error.png" "Ошибка" "Установите nwg-look"
                exit 1
            fi
            nwg-look ;;
		"QT настройки (qt6ct)")
            if ! command -v qt6ct &>/dev/null; then
                notify-send -i "$iDIR/error.png" "Ошибка" "Установите qt6ct"
                exit 1
            fi
            qt6ct ;;
		"QT настройки (qt5ct)")
            if ! command -v qt5ct &>/dev/null; then
                notify-send -i "$iDIR/error.png" "Ошибка" "Установите qt5ct"
                exit 1
            fi
            qt5ct ;;
        "Анимации Hyprland") $scriptsDir/Animations.sh ;;
        "Профили мониторов") $scriptsDir/MonitorProfiles.sh ;;
        "Темы Rofi") $scriptsDir/RofiThemeSelector.sh ;;
        "Поиск по биндам") $scriptsDir/KeyBinds.sh ;;
        "Игровой режим") $scriptsDir/GameMode.sh ;;
        "Светлая/тёмная тема") $scriptsDir/DarkLight.sh ;;
        "Режим Rainbow Borders") rainbow_borders_menu ;;
        *) return ;;  # Do nothing for invalid choices
    esac

    # Открываем выбранный файл в редакторе
    if [ -n "$file" ]; then
        $term -e $edit "$file"
    fi
}

# Check if rofi is already running
if pidof rofi > /dev/null; then
  pkill rofi
fi

main
