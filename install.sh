#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKIP_DEPS=0
SKIP_VIM=0
for arg in "$@"; do
  case "$arg" in
    --skip-deps) SKIP_DEPS=1 ;;
    --skip-vim) SKIP_VIM=1 ;;
    *)
      echo "Неизвестный аргумент: $arg"
      echo "Использование: ./install.sh [--skip-deps] [--skip-vim]"
      exit 1
      ;;
  esac
done

log() { printf '[install] %s\n' "$*"; }
warn() { printf '[install][warn] %s\n' "$*"; }
err() { printf '[install][error] %s\n' "$*" >&2; }

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

require_cmd() {
  local cmd="$1"
  if ! have_cmd "$cmd"; then
    err "Не найдена команда: $cmd"
    exit 1
  fi
}

run_as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  elif have_cmd sudo; then
    sudo "$@"
  else
    return 1
  fi
}

PM="none"
if have_cmd pacman; then
  PM="pacman"
elif have_cmd apt-get; then
  PM="apt"
elif have_cmd dnf; then
  PM="dnf"
fi

install_pkg_best_effort() {
  local pkg="$1"
  case "$PM" in
    pacman)
      run_as_root pacman -S --noconfirm --needed "$pkg" >/dev/null 2>&1 || warn "Не удалось установить пакет: $pkg"
      ;;
    apt)
      run_as_root apt-get install -y "$pkg" >/dev/null 2>&1 || warn "Не удалось установить пакет: $pkg"
      ;;
    dnf)
      run_as_root dnf install -y "$pkg" >/dev/null 2>&1 || warn "Не удалось установить пакет: $pkg"
      ;;
    *)
      warn "Пакетный менеджер не найден. Пропускаю зависимости."
      return 1
      ;;
  esac
}

install_dependencies() {
  [[ "$SKIP_DEPS" -eq 1 ]] && { log "Пропуск установки зависимостей (--skip-deps)."; return; }
  [[ "$PM" == "none" ]] && { warn "Не найден pacman/apt/dnf. Пропускаю зависимости."; return; }

  log "Установка зависимостей через: $PM"

  case "$PM" in
    pacman)
      run_as_root pacman -Sy --noconfirm >/dev/null 2>&1 || warn "Не удалось обновить базы pacman"
      local pkgs=(
        git rsync curl wget unzip jq bc python python-pip
        waybar rofi-wayland swaync wlogout wl-clipboard cliphist swww wallust
        imagemagick ffmpeg grim slurp swappy wf-recorder qalculate-gtk
        playerctl pamixer brightnessctl libnotify pulseaudio
        networkmanager network-manager-applet blueman rfkill
        yad hyprland hypridle hyprlock hyprpicker hyprsunset hyprpaper mpvpaper swaybg
        aylurs-gtk-shell quickshell flatpak alsa-utils
        xdg-desktop-portal-hyprland xdg-utils xdg-user-dirs
        cava btop kitty mlterm qt5ct qt6ct kvantum kvantum-qt5 nwg-look nwg-displays
        pipewire wireplumber polkit-gnome
      )
      ;;
    apt)
      run_as_root apt-get update >/dev/null 2>&1 || warn "Не удалось обновить apt"
      local pkgs=(
        git rsync curl wget unzip jq bc python3 python3-pip
        waybar rofi sway-notification-center wlogout wl-clipboard cliphist swww wallust
        imagemagick ffmpeg grim slurp swappy wf-recorder qalculate-gtk
        playerctl pamixer pulseaudio-utils brightnessctl libnotify-bin
        network-manager network-manager-gnome blueman rfkill
        yad hyprland hypridle hyprlock hyprpicker hyprsunset hyprpaper mpvpaper swaybg
        aylurs-gtk-shell quickshell flatpak alsa-utils
        xdg-desktop-portal-hyprland xdg-utils xdg-user-dirs
        cava btop kitty mlterm qt5ct qt6ct kvantum-manager nwg-look nwg-displays
        pipewire wireplumber policykit-1-gnome
      )
      ;;
    dnf)
      run_as_root dnf makecache >/dev/null 2>&1 || warn "Не удалось обновить кэш dnf"
      local pkgs=(
        git rsync curl wget unzip jq bc python3 python3-pip
        waybar rofi-wayland swaynotificationcenter wlogout wl-clipboard cliphist swww wallust
        ImageMagick ffmpeg grim slurp swappy wf-recorder qalculate
        playerctl pamixer brightnessctl libnotify pulseaudio-utils
        NetworkManager NetworkManager-applet blueman rfkill
        yad hyprland hypridle hyprlock hyprpicker hyprsunset hyprpaper mpvpaper swaybg
        ags quickshell flatpak alsa-utils
        xdg-desktop-portal-hyprland xdg-utils xdg-user-dirs
        cava btop kitty mlterm qt5ct qt6ct kvantum nwg-look nwg-displays
        pipewire wireplumber polkit-gnome
      )
      ;;
  esac

  for pkg in "${pkgs[@]}"; do
    install_pkg_best_effort "$pkg"
  done
}

backup_path() {
  local src="$1"
  local backup_root="$2"

  [[ -e "$src" || -L "$src" ]] || return 0

  local rel="${src#$HOME/}"
  local dest="$backup_root/$rel"
  mkdir -p "$(dirname "$dest")"
  rsync -a "$src" "$dest" >/dev/null 2>&1 || warn "Не удалось создать бэкап: $src"
}

backup_existing() {
  local backup_root="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$backup_root"

  log "Создаю резервную копию в: $backup_root"

  while IFS= read -r item; do
    backup_path "$HOME/.config/$item" "$backup_root"
  done < <(find "$SCRIPT_DIR/config" -mindepth 1 -maxdepth 1 -exec basename {} \;)

  while IFS= read -r item; do
    backup_path "$HOME/$item" "$backup_root"
  done < <(find "$SCRIPT_DIR/home" -mindepth 1 -maxdepth 1 -exec basename {} \;)
}

sync_dotfiles() {
  log "Синхронизирую config -> ~/.config"
  mkdir -p "$HOME/.config"
  rsync -a --exclude '.DS_Store' "$SCRIPT_DIR/config/" "$HOME/.config/"

  log "Синхронизирую home -> ~/"
  rsync -a --exclude '.DS_Store' "$SCRIPT_DIR/home/" "$HOME/"
}

record_repo_location() {
  local marker="$HOME/.config/hypr/.dotfiles_repo"
  mkdir -p "$(dirname "$marker")"
  printf '%s\n' "$SCRIPT_DIR" > "$marker"
}

remove_legacy_user_dirs() {
  local hypr_dir="$HOME/.config/hypr"
  [[ -d "$hypr_dir" ]] || return 0

  log "Удаляю legacy-каталоги с префиксом User* (если есть)"
  find "$hypr_dir" -mindepth 1 -maxdepth 1 -type d -name 'User*' -exec rm -rf {} + 2>/dev/null || true
}

reset_first_boot_marker() {
  log "Сбрасываю маркер первого запуска Hyprland"
  rm -f "$HOME/.config/hypr/.initial_startup_done"
}

setup_theme_defaults() {
  log "Применяю Fallout-тему по умолчанию"
  ln -sfn "$HOME/.config/waybar/configs/[TOP] Fallout" "$HOME/.config/waybar/config"
  ln -sfn "$HOME/.config/waybar/style/[Fallout] Vault-Tec.css" "$HOME/.config/waybar/style.css"

  local wp="$HOME/.config/hypr/wallpaper_effects/fallout-vault-tec.png"
  if [[ -f "$wp" ]]; then
    cp -f "$wp" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_current"
    cp -f "$wp" "$HOME/.config/hypr/wallpaper_effects/.wallpaper_modified"
    mkdir -p "$HOME/Pictures/wallpapers"
    cp -f "$wp" "$HOME/Pictures/wallpapers/fallout-vault-tec.png"
    ln -sfn "$HOME/Pictures/wallpapers/fallout-vault-tec.png" "$HOME/.config/rofi/.current_wallpaper"
  else
    warn "Не найден fallout wallpaper: $wp"
  fi
}

ensure_permissions() {
  log "Проверяю права на скрипты"
  find "$HOME/.config/hypr/scripts" -type f -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
}

install_vimconfig() {
  [[ "$SKIP_VIM" -eq 1 ]] && { log "Пропуск vimconfig (--skip-vim)."; return; }

  local vim_installer="$SCRIPT_DIR/vimconfig/installvimconfig.sh"
  if [[ -f "$vim_installer" ]]; then
    chmod +x "$vim_installer" || true
    log "Запускаю vimconfig/installvimconfig.sh"
    if ! "$vim_installer"; then
      warn "installvimconfig.sh завершился с ошибкой. Продолжаю установку dotfiles."
    fi
  else
    warn "Не найден vimconfig/installvimconfig.sh"
  fi
}

reload_session_best_effort() {
  if have_cmd hyprctl; then
    hyprctl reload >/dev/null 2>&1 || true
  fi

  if [[ -x "$HOME/.config/hypr/scripts/Refresh.sh" ]]; then
    "$HOME/.config/hypr/scripts/Refresh.sh" >/dev/null 2>&1 || true
  fi
}

post_install_diagnostics() {
  local required_cmds=(
    hyprctl waybar rofi jq bc notify-send
    wallust swww cliphist wl-copy grim slurp swappy
    pamixer playerctl brightnessctl
  )
  local optional_cmds=(
    hyprlock hypridle hyprpicker hyprsunset wlogout
    mpvpaper nwg-look nwg-displays qt5ct qt6ct kitty
  )
  local missing_required=()
  local missing_optional=()
  local cmd=""

  for cmd in "${required_cmds[@]}"; do
    have_cmd "$cmd" || missing_required+=("$cmd")
  done
  for cmd in "${optional_cmds[@]}"; do
    have_cmd "$cmd" || missing_optional+=("$cmd")
  done

  if (( ${#missing_required[@]} > 0 )); then
    warn "Не найдены обязательные команды: ${missing_required[*]}"
  else
    log "Проверка обязательных команд: OK"
  fi

  if (( ${#missing_optional[@]} > 0 )); then
    warn "Не найдены опциональные команды: ${missing_optional[*]}"
  fi
}

main() {
  log "Старт установки dotfiles"
  install_dependencies
  require_cmd rsync
  backup_existing
  sync_dotfiles
  record_repo_location
  remove_legacy_user_dirs
  reset_first_boot_marker
  setup_theme_defaults
  ensure_permissions
  install_vimconfig
  post_install_diagnostics
  reload_session_best_effort

  log "Готово. Перезапустите Hyprland-сессию, если изменения не применились сразу."
}

main "$@"
