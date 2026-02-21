#!/usr/bin/env bash

set -euo pipefail

# ==========================================
# ==== Установка конфигурации VimConfig ====
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_VIMRC="$SCRIPT_DIR/.vimrc"
SRC_VIMCONFIGS_DIR="$SCRIPT_DIR/vimconfigs"
SRC_COC_SETTINGS="$SCRIPT_DIR/coc-settings.json"
SRC_CLANG_FORMAT="$SCRIPT_DIR/.clang-format"

DEST_VIM_DIR="$HOME/.vim"
DEST_VIMCONFIGS_DIR="$DEST_VIM_DIR/vimconfigs"
DEST_VIMRC="$HOME/.vimrc"
DEST_VIM_COC_SETTINGS="$DEST_VIM_DIR/coc-settings.json"
DEST_COC_DIR="$HOME/.config/coc"
DEST_COC_SETTINGS="$DEST_COC_DIR/coc-settings.json"
DEST_COC_EXT_DIR="$DEST_COC_DIR/extensions"
DEST_CLANG_FORMAT="$HOME/.clang-format"

OS="$(uname -s)"

log() { echo "[vimconfig] $*"; }
warn() { echo "[vimconfig][warn] $*"; }
err() { echo "[vimconfig][error] $*" >&2; }

have_cmd() {
    command -v "$1" >/dev/null 2>&1
}

append_line_if_missing() {
    local file="$1"
    local line="$2"
    touch "$file"
    grep -Fqx "$line" "$file" || echo "$line" >> "$file"
}

apply_brew_shellenv_if_present() {
    local brew_candidates=(
        "${HOMEBREW_PREFIX:-}/bin/brew"
        "/opt/homebrew/bin/brew"
        "/usr/local/bin/brew"
        "$HOME/.linuxbrew/bin/brew"
    )

    local brew_glob
    for brew_glob in /home/*/.linuxbrew/bin/brew; do
        [[ -x "$brew_glob" ]] && brew_candidates+=("$brew_glob")
    done

    local brew_bin
    for brew_bin in "${brew_candidates[@]}"; do
        [[ -n "$brew_bin" ]] || continue
        if [[ -x "$brew_bin" ]]; then
            eval "$("$brew_bin" shellenv)"
            return 0
        fi
    done
}

ensure_brew() {
    apply_brew_shellenv_if_present
    if have_cmd brew; then
        return 0
    fi

    if [[ "$OS" != "Darwin" && "$OS" != "Linux" ]]; then
        return 1
    fi

    if ! have_cmd curl; then
        warn "curl не найден, не могу установить Homebrew автоматически."
        return 1
    fi

    log "Homebrew не найден, устанавливаю..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        warn "Не удалось установить Homebrew. Будут использованы системные пакетные менеджеры (если доступны)."
        return 1
    }

    apply_brew_shellenv_if_present
    have_cmd brew
}

brew_install_if_missing() {
    local formula="$1"
    if ! have_cmd brew; then
        return 1
    fi

    if brew list --formula "$formula" >/dev/null 2>&1; then
        log "skip: $formula уже установлен."
        return 0
    fi

    log "Устанавливаю $formula (brew)..."
    brew install "$formula"
}

brew_install_cask_if_missing() {
    local cask="$1"
    if ! have_cmd brew; then
        return 1
    fi

    if brew list --cask "$cask" >/dev/null 2>&1; then
        log "skip: $cask уже установлен."
        return 0
    fi

    log "Устанавливаю $cask (brew cask)..."
    brew install --cask "$cask"
}

apt_install_if_missing() {
    local pkg="$1"
    if ! have_cmd apt-get; then
        return 1
    fi

    if dpkg -s "$pkg" >/dev/null 2>&1; then
        log "skip: $pkg уже установлен."
        return 0
    fi

    if have_cmd sudo; then
        log "Устанавливаю $pkg (apt)..."
        sudo apt-get install -y "$pkg"
    else
        warn "sudo недоступен, пропускаю установку $pkg."
    fi
}

dnf_install_if_missing() {
    local pkg="$1"
    if ! have_cmd dnf; then
        return 1
    fi

    if rpm -q "$pkg" >/dev/null 2>&1; then
        log "skip: $pkg уже установлен."
        return 0
    fi

    if have_cmd sudo; then
        log "Устанавливаю $pkg (dnf)..."
        sudo dnf install -y "$pkg"
    else
        warn "sudo недоступен, пропускаю установку $pkg."
    fi
}

pacman_install_if_missing() {
    local pkg="$1"
    if ! have_cmd pacman; then
        return 1
    fi

    if pacman -Q "$pkg" >/dev/null 2>&1; then
        log "skip: $pkg уже установлен."
        return 0
    fi

    if have_cmd sudo; then
        log "Устанавливаю $pkg (pacman)..."
        sudo pacman -S --noconfirm "$pkg"
    else
        warn "sudo недоступен, пропускаю установку $pkg."
    fi
}

ensure_vim_for_brew() {
    # Если vim уже доступен (например /usr/bin/vim), ничего не ставим.
    if have_cmd vim; then
        log "skip: vim уже доступен в PATH ($(command -v vim))."
        return 0
    fi

    # На macOS часто установлен macvim, который конфликтует с формулой vim.
    if [[ "$OS" == "Darwin" ]] && have_cmd brew && brew list --cask macvim >/dev/null 2>&1; then
        warn "macvim установлен. Пропускаю brew install vim (конфликт формул)."
        warn "Если нужен консольный vim из brew: brew unlink macvim && brew install vim"
        return 0
    fi

    brew_install_if_missing vim || true
}

ensure_clangd_for_brew() {
    if have_cmd clangd; then
        log "skip: clangd уже доступен в PATH ($(command -v clangd))."
        return 0
    fi

    # На Homebrew clangd входит в пакет llvm.
    brew_install_if_missing llvm || true

    local llvm_prefix=""
    llvm_prefix="$(brew --prefix llvm 2>/dev/null || true)"
    if [[ -n "$llvm_prefix" && -x "$llvm_prefix/bin/clangd" ]]; then
        append_line_if_missing "$HOME/.zprofile" ""
        append_line_if_missing "$HOME/.zprofile" "# VimConfig llvm"
        append_line_if_missing "$HOME/.zprofile" "export PATH=\"$llvm_prefix/bin:\$PATH\""
        log "clangd найден: $llvm_prefix/bin/clangd"
    else
        warn "clangd не найден после установки llvm. Установите clangd вручную."
    fi
}

ensure_clang_format_for_brew() {
    if have_cmd clang-format; then
        log "skip: clang-format уже доступен в PATH ($(command -v clang-format))."
        return 0
    fi

    # На Homebrew clang-format доступен через llvm.
    brew_install_if_missing llvm || true

    local llvm_prefix=""
    llvm_prefix="$(brew --prefix llvm 2>/dev/null || true)"
    if [[ -n "$llvm_prefix" && -x "$llvm_prefix/bin/clang-format" ]]; then
        append_line_if_missing "$HOME/.zprofile" ""
        append_line_if_missing "$HOME/.zprofile" "# VimConfig llvm"
        append_line_if_missing "$HOME/.zprofile" "export PATH=\"$llvm_prefix/bin:\$PATH\""
        export PATH="$llvm_prefix/bin:$PATH"
        log "clang-format найден: $llvm_prefix/bin/clang-format"
    else
        warn "clang-format не найден после установки llvm. Установите clang-format вручную."
    fi
}

install_base_dependencies() {
    log "Проверка базовых зависимостей..."

    local brew_ready=0
    if ensure_brew; then
        brew_ready=1
    fi

    if [[ "$brew_ready" -eq 1 ]]; then
        # Общее для macOS и Linux через Homebrew.
        brew_install_if_missing git || true
        brew_install_if_missing curl || true
        brew_install_if_missing rsync || true
        brew_install_if_missing unzip || true
        brew_install_if_missing cmake || true
        brew_install_if_missing ninja || true
        brew_install_if_missing ripgrep || true
        brew_install_if_missing fd || true
        brew_install_if_missing shellcheck || true
        brew_install_if_missing python || true
        brew_install_if_missing node@20 || true
        brew_install_if_missing gh || true
        ensure_vim_for_brew
        ensure_clangd_for_brew
        ensure_clang_format_for_brew
        brew_install_if_missing neocmakelsp || true

        # Ноды для CoC: предпочитаем node@20 в PATH.
        if have_cmd brew; then
            brew link --overwrite --force node@20 >/dev/null 2>&1 || true
        fi
        return 0
    fi

    # Fallback на системные менеджеры Linux, если brew недоступен.
    if [[ "$OS" == "Linux" ]]; then
        if have_cmd apt-get && have_cmd sudo; then
            log "Обновляю индекс apt..."
            sudo apt-get update -y

            apt_install_if_missing git || true
            apt_install_if_missing curl || true
            apt_install_if_missing rsync || true
            apt_install_if_missing unzip || true
            apt_install_if_missing cmake || true
            apt_install_if_missing ninja-build || true
            apt_install_if_missing ripgrep || true
            apt_install_if_missing fd-find || true
            apt_install_if_missing shellcheck || true
            apt_install_if_missing nodejs || true
            apt_install_if_missing npm || true
            apt_install_if_missing python3 || true
            apt_install_if_missing python3-pip || true
            apt_install_if_missing gh || true
            apt_install_if_missing vim || true
            apt_install_if_missing clangd || true
            apt_install_if_missing clang-format || true
            apt_install_if_missing fontconfig || true
            return 0
        fi

        if have_cmd dnf; then
            dnf_install_if_missing git || true
            dnf_install_if_missing curl || true
            dnf_install_if_missing rsync || true
            dnf_install_if_missing unzip || true
            dnf_install_if_missing cmake || true
            dnf_install_if_missing ninja-build || true
            dnf_install_if_missing ripgrep || true
            dnf_install_if_missing fd-find || true
            dnf_install_if_missing ShellCheck || true
            dnf_install_if_missing nodejs || true
            dnf_install_if_missing npm || true
            dnf_install_if_missing python3 || true
            dnf_install_if_missing python3-pip || true
            dnf_install_if_missing gh || true
            dnf_install_if_missing vim || true
            dnf_install_if_missing clang-tools-extra || true
            dnf_install_if_missing fontconfig || true
            return 0
        fi

        if have_cmd pacman; then
            pacman_install_if_missing git || true
            pacman_install_if_missing curl || true
            pacman_install_if_missing rsync || true
            pacman_install_if_missing unzip || true
            pacman_install_if_missing cmake || true
            pacman_install_if_missing ninja || true
            pacman_install_if_missing ripgrep || true
            pacman_install_if_missing fd || true
            pacman_install_if_missing shellcheck || true
            pacman_install_if_missing nodejs || true
            pacman_install_if_missing npm || true
            pacman_install_if_missing python || true
            pacman_install_if_missing python-pip || true
            pacman_install_if_missing github-cli || true
            pacman_install_if_missing vim || true
            pacman_install_if_missing clang || true
            pacman_install_if_missing fontconfig || true
            return 0
        fi

        warn "Не найден поддерживаемый пакетный менеджер для Linux (brew/apt/dnf/pacman)."
    else
        warn "Неизвестная ОС ($OS), автоматическая установка зависимостей ограничена."
    fi
}

ensure_global_git_defaults() {
    if ! have_cmd git; then
        warn "git не найден, глобальные настройки push пропущены."
        return 0
    fi

    git config --global push.autoSetupRemote true || true
    git config --global push.default current || true
    git config --global remote.pushDefault origin || true
    log "Глобальные настройки git push применены (autoSetupRemote/current/origin)."
}

detect_node_bin() {
    local candidates=()

    if have_cmd brew; then
        local node_prefix=""
        node_prefix="$(brew --prefix node@20 2>/dev/null || true)"
        if [[ -n "$node_prefix" ]]; then
            candidates+=("$node_prefix/bin/node")
        fi
    fi

    candidates+=(
        "/opt/homebrew/opt/node@20/bin/node"
        "/usr/local/opt/node@20/bin/node"
        "$HOME/.linuxbrew/opt/node@20/bin/node"
    )

    local node_path
    for node_path in "${candidates[@]}"; do
        if [[ -x "$node_path" ]]; then
            echo "$node_path"
            return 0
        fi
    done

    if have_cmd node; then
        command -v node
        return 0
    fi

    return 1
}

detect_npm_bin() {
    local candidates=()

    if have_cmd brew; then
        local node_prefix=""
        node_prefix="$(brew --prefix node@20 2>/dev/null || true)"
        if [[ -n "$node_prefix" ]]; then
            candidates+=("$node_prefix/bin/npm")
        fi
    fi

    candidates+=(
        "/opt/homebrew/opt/node@20/bin/npm"
        "/usr/local/opt/node@20/bin/npm"
        "$HOME/.linuxbrew/opt/node@20/bin/npm"
    )

    local npm_path
    for npm_path in "${candidates[@]}"; do
        if [[ -x "$npm_path" ]]; then
            echo "$npm_path"
            return 0
        fi
    done

    if have_cmd npm; then
        command -v npm
        return 0
    fi

    return 1
}

install_python_helpers() {
    if ! have_cmd python3; then
        warn "python3 не найден, Python helper-пакеты пропущены."
        return 0
    fi

    log "Обновляю pip и ставлю Python helper-пакеты..."
    python3 -m pip install --user --upgrade pip setuptools wheel >/dev/null 2>&1 || true
    python3 -m pip install --user --upgrade pynvim >/dev/null 2>&1 || true
}

install_coc_extensions() {
    local npm_bin
    if ! npm_bin="$(detect_npm_bin)"; then
        warn "npm не найден, установка CoC extensions пропущена."
        return 0
    fi

    mkdir -p "$DEST_COC_EXT_DIR"
    cd "$DEST_COC_EXT_DIR"

    if [[ ! -f package.json ]]; then
        cat > package.json <<'JSON'
{
  "dependencies": {}
}
JSON
    fi

    log "Устанавливаю CoC extensions..."
    "$npm_bin" install \
        coc-clangd coc-cmake coc-css coc-json coc-pyright coc-rust-analyzer coc-sh coc-tsserver coc-yaml \
        pyright \
        vscode-langservers-extracted \
        --save --no-audit --no-fund

    # Удаляем известные конфликтные расширения.
    "$npm_bin" remove coc-python coc-omnisharp coc-html --no-audit --no-fund >/dev/null 2>&1 || true
}

find_existing_vcpkg_root() {
    local roots=()

    if [[ -n "${VCPKG_ROOT:-}" ]]; then
        roots+=("$VCPKG_ROOT")
    fi

    roots+=("$HOME/vcpkg" "$HOME/.vcpkg" "$SCRIPT_DIR/vcpkg")

    local vcpkg_exe
    if vcpkg_exe="$(command -v vcpkg 2>/dev/null)"; then
        roots+=("$(cd "$(dirname "$vcpkg_exe")" && pwd)")
    fi

    local root
    for root in "${roots[@]}"; do
        [[ -z "$root" ]] && continue
        if [[ -f "$root/scripts/buildsystems/vcpkg.cmake" ]]; then
            echo "$root"
            return 0
        fi
    done

    return 1
}

bootstrap_vcpkg() {
    local root="$1"
    if [[ ! -d "$root" ]]; then
        return 1
    fi

    if [[ -x "$root/vcpkg" ]]; then
        return 0
    fi

    if [[ -x "$root/bootstrap-vcpkg.sh" ]]; then
        log "Bootstrap vcpkg..."
        (cd "$root" && ./bootstrap-vcpkg.sh -disableMetrics)
    else
        warn "Не найден bootstrap-vcpkg.sh в $root"
        return 1
    fi
}

ensure_vcpkg() {
    local root=""

    if root="$(find_existing_vcpkg_root)"; then
        log "vcpkg найден: $root"
    else
        if ! have_cmd git; then
            warn "git не найден, не могу скачать vcpkg автоматически."
            return 0
        fi

        root="$HOME/vcpkg"
        if [[ ! -d "$root" ]]; then
            log "Скачиваю vcpkg в $root ..."
            git clone https://github.com/microsoft/vcpkg.git "$root" || {
                warn "Не удалось клонировать vcpkg."
                return 0
            }
        fi
    fi

    bootstrap_vcpkg "$root" || true

    export VCPKG_ROOT="$root"
    log "VCPKG_ROOT=$VCPKG_ROOT"

    append_line_if_missing "$HOME/.zprofile" ""
    append_line_if_missing "$HOME/.zprofile" "# VimConfig vcpkg"
    append_line_if_missing "$HOME/.zprofile" "export VCPKG_ROOT=\"$VCPKG_ROOT\""
    append_line_if_missing "$HOME/.zprofile" "export PATH=\"\$PATH:\$VCPKG_ROOT\""
}

copy_config_files() {
    if [[ ! -f "$SRC_VIMRC" ]]; then
        err "Не найден файл $SRC_VIMRC"
        exit 1
    fi

    if [[ ! -d "$SRC_VIMCONFIGS_DIR" ]]; then
        err "Не найдена директория $SRC_VIMCONFIGS_DIR"
        exit 1
    fi

    mkdir -p "$DEST_VIMCONFIGS_DIR"

    if [[ -f "$DEST_VIMRC" ]]; then
        local backup_path="$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$DEST_VIMRC" "$backup_path"
        log "Сделан backup: $backup_path"
    fi

    if have_cmd rsync; then
        rsync -a --delete \
            --exclude '.DS_Store' \
            --exclude '*.swp' \
            --exclude '*.swo' \
            "$SRC_VIMCONFIGS_DIR"/ "$DEST_VIMCONFIGS_DIR"/
    else
        warn "rsync не найден, использую cp (без удаления лишних файлов)."
        cp -a "$SRC_VIMCONFIGS_DIR"/. "$DEST_VIMCONFIGS_DIR"/
        find "$DEST_VIMCONFIGS_DIR" -name '.DS_Store' -delete || true
        find "$DEST_VIMCONFIGS_DIR" -name '*.swp' -delete || true
        find "$DEST_VIMCONFIGS_DIR" -name '*.swo' -delete || true
    fi

    cp "$SRC_VIMRC" "$DEST_VIMRC"
    log "Скопирован: $DEST_VIMRC"

    if [[ -f "$SRC_COC_SETTINGS" ]]; then
        mkdir -p "$DEST_VIM_DIR"
        cp "$SRC_COC_SETTINGS" "$DEST_VIM_COC_SETTINGS"
        log "Скопирован: $DEST_VIM_COC_SETTINGS"

        mkdir -p "$DEST_COC_DIR"
        cp "$SRC_COC_SETTINGS" "$DEST_COC_SETTINGS"
        log "Скопирован: $DEST_COC_SETTINGS"
    fi

    if [[ -f "$SRC_CLANG_FORMAT" ]]; then
        if [[ -f "$DEST_CLANG_FORMAT" ]]; then
            local clang_backup_path="$HOME/.clang-format.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$DEST_CLANG_FORMAT" "$clang_backup_path"
            log "Сделан backup: $clang_backup_path"
        fi
        cp "$SRC_CLANG_FORMAT" "$DEST_CLANG_FORMAT"
        log "Скопирован: $DEST_CLANG_FORMAT"
    fi
}

install_vim_plug() {
    if ! have_cmd curl; then
        warn "curl не найден, установка vim-plug пропущена."
        return 0
    fi

    curl -fsLo "$DEST_VIM_DIR/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    log "vim-plug установлен/обновлен."
}

install_fonts_via_brew() {
    if ! have_cmd brew; then
        return 1
    fi

    if [[ "$OS" != "Darwin" ]]; then
        return 1
    fi

    log "Устанавливаю набор Nerd Fonts через Homebrew Cask..."
    brew tap homebrew/cask-fonts >/dev/null 2>&1 || true

    local casks=(
        "font-jetbrains-mono-nerd-font"
        "font-fira-code-nerd-font"
        "font-hack-nerd-font"
        "font-caskaydia-cove-nerd-font"
        "font-meslo-lg-nerd-font"
        "font-source-code-pro"
    )

    local cask
    for cask in "${casks[@]}"; do
        brew_install_cask_if_missing "$cask" || true
    done

    return 0
}

install_fonts_from_nerd_fonts_release() {
    if ! have_cmd curl || ! have_cmd unzip; then
        warn "curl/unzip недоступны, установка шрифтов пропущена."
        return 0
    fi

    local font_dir=""
    if [[ "$OS" == "Darwin" ]]; then
        font_dir="$HOME/Library/Fonts"
    elif [[ "$OS" == "Linux" ]]; then
        font_dir="$HOME/.local/share/fonts"
    fi

    if [[ -z "$font_dir" ]]; then
        warn "Неизвестная ОС для установки шрифтов: $OS"
        return 0
    fi

    mkdir -p "$font_dir"

    local temp_dir
    temp_dir="$(mktemp -d)"

    local fonts=(
        "JetBrainsMono"
        "FiraCode"
        "Hack"
        "CascadiaCode"
        "Meslo"
        "SourceCodePro"
        "Iosevka"
        "Terminus"
    )

    local font
    for font in "${fonts[@]}"; do
        local zip_path="$temp_dir/${font}.zip"
        local extract_dir="$temp_dir/$font"
        local url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"

        log "Скачиваю шрифт $font..."
        if ! curl -fL "$url" -o "$zip_path" >/dev/null 2>&1; then
            warn "Не удалось скачать $font, пропускаю."
            continue
        fi

        mkdir -p "$extract_dir"
        unzip -oq "$zip_path" -d "$extract_dir" || {
            warn "Не удалось распаковать $font, пропускаю."
            continue
        }

        find "$extract_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "$font_dir"/ \;
    done

    if [[ "$OS" == "Linux" ]] && have_cmd fc-cache; then
        fc-cache -f "$font_dir" >/dev/null 2>&1 || true
    fi

    rm -rf "$temp_dir"
    log "Шрифты установлены в: $font_dir"
}

install_fonts_best_effort() {
    # На macOS сначала пытаемся через cask, затем fallback на прямой download.
    if install_fonts_via_brew; then
        log "Шрифты через brew cask установлены (или уже были установлены)."
    else
        install_fonts_from_nerd_fonts_release
    fi
}

ensure_gh_auth() {
    if ! have_cmd gh; then
        warn "gh не найден, шаг gh auth login пропущен."
        return 0
    fi

    if gh auth status >/dev/null 2>&1; then
        log "gh уже авторизован."
        return 0
    fi

    if [[ -t 0 && -t 1 ]]; then
        log "Запускаю gh auth login (интерактивно)..."
        gh auth login || warn "gh auth login завершился с ошибкой. Можно повторить позже вручную: gh auth login"
    else
        warn "Нет интерактивного TTY. Выполните вручную: gh auth login"
    fi
}

install_vim_plugins() {
    if ! have_cmd vim; then
        warn "vim не найден в PATH, PlugInstall пропущен."
        return 0
    fi

    log "Устанавливаем плагины Vim..."
    vim -Nu "$DEST_VIMRC" -N -n -es \
        -c 'set nomore' \
        -c 'silent! PlugInstall --sync' \
        -c 'qa!' || warn "PlugInstall завершился с ошибкой."
}

main() {
    log "Установка VimConfig из: $SCRIPT_DIR"

    install_base_dependencies
    ensure_global_git_defaults
    copy_config_files
    ensure_vcpkg
    install_vim_plug
    install_python_helpers
    install_coc_extensions
    install_fonts_best_effort
    ensure_gh_auth
    install_vim_plugins

    local node_bin=""
    if node_bin="$(detect_node_bin)"; then
        log "Node для CoC: $node_bin"
    else
        warn "Node не найден. CoC может не запуститься до установки Node.js."
    fi

    log "Готово. Конфигурация установлена."
}

main "$@"
