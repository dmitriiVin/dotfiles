# VimConfig

Максимально подробная модульная конфигурация Vim для разработки с фокусом на:

- C/C++ + CMake,
- постоянный мониторинг ошибок через quickfix,
- быстрый цикл `generate -> build -> run`,
- локальные версии кода `Debug/Release`,
- удобный Git/Fugitive workflow,
- автоподключение тем и шрифтов.

Конфигурация ставится из этого репозитория в `~/.vim` и `~/.vimrc`.

---

## 1. Основные возможности

1. CMake workflow на горячих клавишах:
   - `F6` — generate,
   - `F7` — build,
   - `F8` — выбор исполняемого файла,
   - `F9` — запуск,
   - `F10` — переключение `Debug/Release`.
2. Локальные профили кода:
   - `.vim-code-profiles/debug`
   - `.vim-code-profiles/release`
   - при `F10` код синхронизируется между профилями.
3. Диагностика и quickfix:
   - окно quickfix используется как монитор,
   - не обязано перехватывать основной фокус,
   - навигация по ошибкам отдельными биндами.
4. LSP/диагностика через `coc.nvim`:
   - C/C++, CMake, Python, Rust, JS/TS, JSON, CSS, YAML, Shell.
5. Git-инструменты:
   - status/commit/push/pull,
   - интерактивное переключение и создание веток,
   - поддержка `worktree`.
6. Автоматическое создание удалённого репозитория GitHub (опционально):
   - при `git init` из Vim-функций добавляется `origin`,
   - если репозитория на GitHub нет, он может быть создан через `gh`.
7. Темы и шрифты:
   - интерактивный выбор темы (`\th`) и шрифта (`\ff`),
   - запоминание темы между запусками Vim.

---

## 2. Структура репозитория

```text
vimconfig/
├── .vimrc
├── README.md
├── coc-settings.json
├── installvimconfig.sh
└── vimconfigs/
    ├── autocmd.vim
    ├── mappings.vim
    ├── options.vim
    ├── plugins.vim
    ├── theme_state.vim
    ├── colors/
    │   └── *.vim
    └── functions/
        ├── cmake.vim
        ├── coc_russian.vim
        ├── github.vim
        ├── help.vim
        ├── nerdtree.vim
        ├── runcode.vim
        └── terminal.vim
```

---

## 3. Что делает `installvimconfig.sh`

Скрипт:

1. Ставит зависимости (предпочтительно через Homebrew и на macOS, и на Linux).
2. При отсутствии brew пробует fallback на системный пакетный менеджер Linux (`apt`, `dnf`, `pacman`).
3. Применяет безопасные глобальные git-настройки для push:
   - `push.autoSetupRemote=true`
   - `push.default=current`
   - `remote.pushDefault=origin`
4. Делает backup существующего `~/.vimrc`.
5. Копирует:
   - `.vimrc` -> `~/.vimrc`
   - `vimconfigs/*` -> `~/.vim/vimconfigs/`
   - `coc-settings.json` -> `~/.vim/coc-settings.json` и `~/.config/coc/coc-settings.json`
6. Ставит/обновляет `vim-plug`.
7. Ставит CoC-расширения через npm.
8. Ставит/обновляет глобальный `~/.clang-format` из шаблона репозитория.
9. Ставит набор Nerd Fonts (расширенный список).
10. Проверяет `gh auth status` и запускает `gh auth login` (если нужен интерактивный вход).
11. Запускает `:PlugInstall`.

---

## 4. Автоустановка зависимостей

### 4.1 Через Homebrew (приоритетно)

Скрипт пытается установить:

- `git`
- `curl`
- `rsync`
- `unzip`
- `cmake`
- `ninja`
- `ripgrep`
- `fd`
- `shellcheck`
- `python`
- `node@20`
- `gh`
- `vim`
- `llvm` (включает `clangd`)
- `clang-format` (через `llvm` в Homebrew)
- `neocmakelsp`

### 4.2 Linux fallback (если brew не удалось)

- `apt` / `dnf` / `pacman` best-effort установка аналогичных пакетов.
- Для Linux дополнительно ставится `fontconfig` (для `fc-cache`).
- Для Linux отдельно добавлена установка `clang-format`.

### 4.3 Глобальный clang-format

- В репозитории есть файл `.clang-format` в корне `vimconfig`.
- Скрипт копирует его в `~/.clang-format` (с backup старой версии).
- Это используется как глобальный стиль, если в проекте нет локального `.clang-format`.

---

## 5. Шрифты

### 5.1 Что ставится автоматически

На macOS через `brew cask` (если возможно):

- `font-jetbrains-mono-nerd-font`
- `font-fira-code-nerd-font`
- `font-hack-nerd-font`
- `font-caskaydia-cove-nerd-font`
- `font-meslo-lg-nerd-font`
- `font-source-code-pro`

Fallback (и основной путь на Linux) — загрузка из Nerd Fonts release:

- JetBrainsMono
- FiraCode
- Hack
- CascadiaCode
- Meslo
- SourceCodePro
- Iosevka
- Terminus

### 5.2 Где оказываются шрифты

- macOS: `~/Library/Fonts`
- Linux: `~/.local/share/fonts`

---

## 6. Установка

### 6.1 Быстрый старт

```bash
git clone <your-vimconfig-repo-url>
cd vimconfig
chmod +x installvimconfig.sh
./installvimconfig.sh
```

### 6.2 После установки

Открой Vim и при необходимости выполни:

```vim
:CocRestart
:PlugInstall
```

---

## 7. Глобальные переменные в `.vimrc`

Верхние ключевые параметры:

```vim
let g:git_default_remote_url_template = 'https://github.com/{owner}/{repo}.git'
let g:git_auto_create_github_repo = 1
let g:git_auto_create_repo_visibility = 'public'
```

Что это даёт:

- шаблон `origin` для новых локальных репозиториев,
- авто-создание GitHub репозитория через `gh repo create` при необходимости,
- выбор видимости (`public` или `private`).

---

## 8. Автоматическое создание GitHub-репозитория

Логика работает в Git-функциях (`vimconfigs/functions/github.vim`):

1. Если в рабочей папке нет `.git`, при Git-действиях можно запустить init.
2. После init автоматически добавляется `origin` из шаблона `g:git_default_remote_url_template`.
3. Если remote недоступен и это `github.com`, выполняется попытка `gh repo create owner/repo`.
4. Для этого нужны:
   - установленный `gh`,
   - авторизация `gh auth login`.

Если `gh` не установлен или не авторизован, выводится понятное сообщение.

---

## 9. CoC и языки

### 9.1 Устанавливаемые расширения CoC

- `coc-clangd`
- `coc-cmake`
- `coc-css`
- `coc-json`
- `coc-pyright`
- `coc-rust-analyzer`
- `coc-sh`
- `coc-tsserver`
- `coc-yaml`

Также ставятся npm-пакеты:

- `pyright`
- `vscode-langservers-extracted`

### 9.2 Важное для Python

- Python-диагностика работает через `coc-pyright`.
- Убедись, что `node` и `npm` доступны в PATH.

### 9.3 Важное для CMake

- Конфиг использует `neocmakelsp` в `coc-settings.json`.
- Скрипт пытается установить `neocmakelsp` через brew.

---

## 10. CMake workflow подробно

### 10.1 Поиск CMakeLists

Функции в `cmake.vim`:

- находят корневой `CMakeLists.txt` в рабочем дереве,
- игнорируют `.vim-code-profiles/` при поиске CMake,
- запоминают последний CMake-контекст.

### 10.2 Build-директории

Используются каталоги вида:

- `build/debug`
- `build/release`

и контекст последней сборки (`g:cmake_last_*`).

### 10.3 `F10` и профили кода

При переключении build type:

1. Проверяются несохранённые буферы.
2. Текущая версия синхронизируется в активный профиль.
3. Целевой профиль копируется в рабочую директорию.
4. Буферы перечитываются.

Таким образом можно держать разные версии исходников для debug/release.

---

## 11. Quickfix и диагностика

Ключевые команды:

- `Ctrl+W` — открыть quickfix monitor
- `Ctrl+Q` — закрыть quickfix
- `\qn` / `\qp` — next/prev ошибка
- `\qf` / `\ql` — first/last ошибка

Quickfix используется как отдельная панель мониторинга ошибок.

---

## 12. Полный список основных хоткеев

Лидер-клавиша: `\`

### 12.1 Базовые

- `Ctrl+S` — сохранить файл
- `Ctrl+X` — закрыть текущий буфер (`:bp|bd #`)
- `Ctrl+B` — закрыть текущий буфер (`:bp|bd #`)
- `Ctrl+Z` — undo

### 12.2 Буферы и окна

- `Tab` / `Shift+Tab` — цикл по рабочим буферам
- `Tab + ←/→/↑/↓` — переход между окнами
- `Shift + ←/→/↑/↓` — быстрый переход между окнами
- `Ctrl+Tab` — переключение на предыдущий буфер

### 12.3 Поиск/редактирование

- `Ctrl+F` — поиск
- `Ctrl+H` — `:nohlsearch`
- `Ctrl+A` — выделить всё
- `Ctrl+D` / `Ctrl+K` — удалить строку/выделение
- `\c` — комментарий через `vim-commentary`

### 12.4 NERDTree

- `F1` — открыть/закрыть NERDTree
- `F4` — обновить NERDTree
- `Ctrl+N` — создать файл/директорию в NERDTree
- `Ctrl+D` — удалить файл/директорию в NERDTree

### 12.5 CMake

- `F3` — удалить `build` текущего проекта
- `F6` — генерация CMake
- `F7` — сборка
- `F8` — интерактивный выбор исполняемого файла
- `F9` — запуск выбранного исполняемого файла
- `F10` — переключение `Debug/Release`
- `F12` — создать/открыть `CMakeLists.txt` в NERDTree
- `\ru` — быстрый цикл `generate+build+run`
- `\bt` — показать текущий build type
- `\ct` — показать выбранный target

### 12.6 Git/Fugitive

- `\gs` — `:Git`
- `\gc` — `:Git commit`
- `\gp` — `:Git push`
- `\gl` — `:Git pull`
- `\go` — `:GBrowse`
- `\gb` — интерактивно переключить ветку
- `\gn` — создать и переключить новую ветку
- `\gv` — переключить Git worktree
- `\gm` — настроить ветки для `Debug/Release`
- `\gd` — перейти на Debug-ветку
- `\gr` — перейти на Release-ветку
- `\gD` — запомнить текущую ветку как Debug
- `\gR` — запомнить текущую ветку как Release

Дополнительные команды:

- `:GitBranchSwitch` — интерактивное переключение ветки
- `:GitBranchCreate` — создание новой ветки

### 12.7 Темы/шрифты/справка

- `\th` — выбор темы (preset + scheme), применение сразу
- `\ff` — выбор GUI-шрифта
- `\h` — встроенная справка
- `Esc` в справке — закрыть help и вернуться к коду

---

## 13. Темы

### 13.1 Источники тем

1. Локальные preset-файлы из `vimconfigs/colors/*.vim`.
2. Все colorscheme из `runtimepath` (включая темы из плагинов, например github).

### 13.2 Сортировка

Список в `\th`:

- сначала `[preset]`, затем `[scheme]`,
- внутри каждой группы сортировка по алфавиту.

### 13.3 Персистентность

Последняя выбранная тема сохраняется в `vimconfigs/theme_state.vim` и подгружается при старте.

---

## 14. Шрифты в Vim

- `\ff` работает только в GUI Vim (`has('gui_running')`).
- В терминальном Vim шрифт меняется в настройках терминала, не внутри Vim.
- В preset уже добавлен `Fixedsys Excelsior 3.01`.

---

## 15. Troubleshooting

### 15.1 `Repository not found` при `git push`

Причина: remote указывает на GitHub-репозиторий, который ещё не создан.

Что делать:

1. Убедиться, что установлен `gh`.
2. Выполнить `gh auth login`.
3. Повторить Git-действие из Vim (или пуш).

### 15.2 `gh auth login` не запускается из скрипта

Скрипт запускает `gh auth login` только в интерактивном терминале (TTY).
Если установка шла неинтерактивно, выполни вручную:

```bash
gh auth login
```

### 15.3 `CocRestart`/LSP не поднимается

Проверить:

```bash
node -v
npm -v
vim --version
```

В Vim:

```vim
:CocInfo
:CocCommand workspace.showOutput
```

### 15.4 Нет Python-диагностики

Проверить, что установлен `coc-pyright` и `pyright`:

```bash
ls ~/.config/coc/extensions/node_modules | grep -E "coc-pyright|pyright"
```

---

## 16. Обновление конфигурации

```bash
cd <path-to-vimconfig-repo>
git pull
./installvimconfig.sh
```

---

## 17. Где смотреть реализацию

- `<repo>/vimconfig/.vimrc`
- `<repo>/vimconfig/coc-settings.json`
- `<repo>/vimconfig/installvimconfig.sh`
- `<repo>/vimconfig/vimconfigs/mappings.vim`
- `<repo>/vimconfig/vimconfigs/options.vim`
- `<repo>/vimconfig/vimconfigs/functions/cmake.vim`
- `<repo>/vimconfig/vimconfigs/functions/github.vim`
- `<repo>/vimconfig/vimconfigs/functions/help.vim`

---

## 18. Итог

Этот репозиторий рассчитан на сценарий "установить на чистую систему и сразу работать":

- зависимости подтягиваются автоматически,
- CoC/плагины ставятся автоматически,
- темы и шрифты доступны сразу,
- Git workflow с локальными ветками и автосозданием GitHub-репозитория интегрирован прямо в Vim.
