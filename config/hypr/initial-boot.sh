#!/usr/bin/env bash
# Скрипт первого запуска (выполняется один раз после установки)

# Этот скрипт можно удалить после успешного первого запуска.
# Маркер выполнения: ~/.config/hypr/.initial_startup_done

# Variables
scriptsDir=$HOME/.config/hypr/scripts
wallpaper=$HOME/.config/hypr/wallpaper_effects/fallout-vault-tec.png
waybar_style="$HOME/.config/waybar/style/[Fallout] Vault-Tec.css"
kvantum_theme="catppuccin-mocha-blue"
color_scheme="prefer-dark"
gtk_theme="Flat-Remix-GTK-Blue-Dark"
icon_theme="Flat-Remix-Blue-Dark"
cursor_theme="Bibata-Modern-Ice"

swww="swww img"
effect="--transition-bezier .43,1.19,1,.4 --transition-fps 30 --transition-type grow --transition-pos 0.925,0.977 --transition-duration 2"

# Если маркер отсутствует, выполняем первичную настройку
if [ ! -f "$HOME/.config/hypr/.initial_startup_done" ]; then
    sleep 1
    # Инициализация wallust и обоев
	if [ -f "$wallpaper" ]; then
		wallust run -s "$wallpaper" > /dev/null
		swww query || swww-daemon && $swww "$wallpaper" $effect
	    "$scriptsDir/WallustSwww.sh" > /dev/null 2>&1 & 
	fi
     
    # Применяем тему GTK и курсор
    gsettings set org.gnome.desktop.interface color-scheme $color_scheme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface gtk-theme $gtk_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface icon-theme $icon_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-theme $cursor_theme > /dev/null 2>&1 &
    gsettings set org.gnome.desktop.interface cursor-size 24 > /dev/null 2>&1 &

     # Для NixOS используем dconf
	if [ -n "$(grep -i nixos < /etc/os-release)" ]; then
      gsettings set org.gnome.desktop.interface color-scheme "'$color_scheme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/gtk-theme "'$gtk_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/icon-theme "'$icon_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/cursor-theme "'$cursor_theme'" > /dev/null 2>&1 &
      dconf write /org/gnome/desktop/interface/cursor-size "24" > /dev/null 2>&1 &
	fi
       
    # Применяем тему Kvantum
    kvantummanager --set "$kvantum_theme" > /dev/null 2>&1 &

	# Применяем стиль Waybar по умолчанию
	if [ -L "$HOME/.config/waybar/config" ] || [ -f "$HOME/.config/waybar/config" ]; then
    	ln -sf "$waybar_style" "$HOME/.config/waybar/style.css"
    	"$scriptsDir/Refresh.sh" > /dev/null 2>&1 &
	fi

    # Ставим маркер выполнения
    touch "$HOME/.config/hypr/.initial_startup_done"

    exit
fi
