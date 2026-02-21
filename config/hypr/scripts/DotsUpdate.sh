#!/usr/bin/env bash
# Проверка обновления локального репозитория конфигов

set -euo pipefail

iDIR="$HOME/.config/swaync/images"

# Ищем каталог dotfiles в типичных местах
marker_file="$HOME/.config/hypr/.dotfiles_repo"
candidates=()

if [[ -f "$marker_file" ]]; then
  marker_repo="$(head -n1 "$marker_file" 2>/dev/null || true)"
  [[ -n "$marker_repo" ]] && candidates+=("$marker_repo")
fi

candidates+=(
  "$HOME/Desktop/dotfiles"
  "$HOME/dotfiles"
  "$HOME/.dotfiles"
)

repo_dir=""
for p in "${candidates[@]}"; do
  if [[ -d "$p/.git" ]]; then
    repo_dir="$p"
    break
  fi
done

if [[ -z "$repo_dir" ]]; then
  notify-send -i "$iDIR/error.png" "Обновление конфигов" "Не найден локальный git-репозиторий dotfiles. Запустите install.sh повторно."
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  notify-send -i "$iDIR/error.png" "Обновление конфигов" "Не найден git. Установите git."
  exit 1
fi

# Проверка наличия удалённого
if ! git -C "$repo_dir" remote get-url origin >/dev/null 2>&1; then
  notify-send -i "$iDIR/error.png" "Обновление конфигов" "В репозитории не настроен origin."
  exit 1
fi

# Обновляем информацию и показываем статус
if ! git -C "$repo_dir" fetch --quiet origin; then
  notify-send -i "$iDIR/error.png" "Обновление конфигов" "Не удалось получить изменения с origin."
  exit 1
fi

local_ref=$(git -C "$repo_dir" rev-parse @)
remote_ref=$(git -C "$repo_dir" rev-parse @{u} 2>/dev/null || true)

if [[ -z "$remote_ref" ]]; then
  notify-send -i "$iDIR/error.png" "Обновление конфигов" "Для текущей ветки не настроен upstream."
  exit 1
fi

if [[ "$local_ref" == "$remote_ref" ]]; then
  notify-send -i "$iDIR/note.png" "Обновление конфигов" "Локальная версия уже актуальна."
  exit 0
fi

if command -v kitty >/dev/null 2>&1; then
  kitty -e bash -lc "cd '$repo_dir' && git pull --rebase --autostash && echo && echo 'Обновление завершено. Нажмите Enter для выхода.' && read -r"
else
  git -C "$repo_dir" pull --rebase --autostash
fi

notify-send -u low -i "$iDIR/note.png" "Обновление конфигов" "Изменения загружены. Перезапустите сессию Hyprland при необходимости."
