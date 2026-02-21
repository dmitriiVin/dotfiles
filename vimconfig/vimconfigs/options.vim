" === ОСНОВНЫЕ НАСТРОЙКИ ===
syntax on
set number
set autoindent
set smartindent
set hidden
set signcolumn=auto
highlight SignColumn ctermbg=NONE guibg=NONE

" Настройка табуляции
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab

" Поиск
set hlsearch                    " подсвечивать результаты поиска
set incsearch                   " инкрементальный поиск
set ignorecase                  " игнорировать регистр
set smartcase                   " умный регистр

" Интерфейс
set mouse=a
set wildmenu
set wildmode=longest:full,full
set showcmd                     " показывать незавершенные команды
set cursorline                  " подсветка текущей строки
set scrolloff=5                 " отступ от краев при скролле
set timeout
set timeoutlen=300

" Терминальные keycodes для Shift+стрелок (особенно Up/Down)
if !has('gui_running')
    set ttimeout
    set ttimeoutlen=80
    execute 'set <S-Up>=\e[1;2A'
    execute 'set <S-Down>=\e[1;2B'
    execute 'set <S-Left>=\e[1;2D'
    execute 'set <S-Right>=\e[1;2C'
endif

" Убираем подсветку текущей строки (зеленую) или делаем ее менее навязчивой
" highlight CursorLine ctermbg=235 cterm=none  " темно-серый вместо зеленого
set nocursorline                " или полностью отключаем

" Переносы
set wrap
set linebreak

let g:cmake_build_type = 'Debug'
let g:cmake_selected_target = ''
let g:cmake_sync_code_profile_with_build_type = 1

" === ПОДСВЕТКА СИНТАКСИСА C++ ===

"let g:cpp_attributes_highlight = 1
"let g:cpp_member_highlight = 1

" Глобальная переменная для хранения выбранного таргета
let g:cmake_selected_target = ''

" Открывать файлы в фоновом режиме без переключения на них
let g:NERDTreeQuitOnOpen = 0

" Не закрывать NERDTree при открытии файла
let g:NERDTreeAutoDeleteBuffer = 0

" Показывать скрытые файлы
let g:NERDTreeShowHidden = 1

" Размер окна NERDTree
let g:NERDTreeWinSize = 35

" Автоматически обновлять корень при смене директории
let g:NERDTreeChDirMode = 2

set wildmenu
set wildmode=longest:list,full
set wildignorecase
set wildignore=*.o,*.obj,*.bak,*.exe,*.pyc,*.jpg,*.gif,*.png
set path=.,**  " искать в текущей директории и поддиректориях

" Игнорировать некоторые файлы
let g:NERDTreeIgnore = ['\.pyc$', '__pycache__', '\.git$', '\.DS_Store']

" Показывать строку статуса
let g:NERDTreeStatusline = '%#NonText#'

" Airline
let g:airline_theme = 'gruvbox'
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#tabline#show_tabs = 0
let g:airline#extensions#tabline#fnamemod = ':t'
set showtabline=2

" Текущий build type (Debug/Release) в правой части статусной строки.
function! VimConfigBuildTypeLabel() abort
    return exists('g:cmake_build_type') && !empty(g:cmake_build_type) ? g:cmake_build_type : '-'
endfunction
let g:airline_section_z = 'BT:%{VimConfigBuildTypeLabel()} | %3p%% ☰ %l/%L'

" Открывать Git статус в том же окне
let g:fugitive_UseSplit = 0

" Для диффов
let g:fugitive_DiffVertical = 0  " используем horizontal diff

" === ТЕМЫ ===
let g:theme_presets_dir = expand('~/.vim/vimconfigs/colors')
let g:quickfix_monitor_height = get(g:, 'quickfix_monitor_height', 8)
let g:theme_state_file = get(g:, 'theme_state_file', expand('~/.vim/vimconfigs/theme_state.vim'))

" === Сравнение тем по имени (алфавитная сортировка) ===
function! s:CompareThemeByName(left, right) abort
    let l:left = tolower(a:left.name)
    let l:right = tolower(a:right.name)
    if l:left ==# l:right
        return 0
    endif
    return l:left ># l:right ? 1 : -1
endfunction

" === Применить тему по типу источника (preset/scheme) ===
function! s:ApplyTheme(type, value) abort
    if a:type ==# 'preset'
        execute 'source ' . fnameescape(a:value)
    else
        execute 'silent! colorscheme ' . a:value
    endif

    if exists('*airline#load_theme') && exists('g:airline_theme')
        silent! call airline#load_theme(g:airline_theme)
    endif
endfunction

" === Сохранить выбранную тему для автозагрузки на следующем старте ===
function! s:SaveThemeSelection(item) abort
    let l:lines = [
                \ '" Auto-generated. Last selected theme.',
                \ 'let g:last_theme_type = ' . string(a:item.type),
                \ 'let g:last_theme_value = ' . string(a:item.value),
                \ ]
    call writefile(l:lines, g:theme_state_file)
endfunction

" === Собрать список доступных тем ===
function! s:GetThemeOptions() abort
    let l:preset_items = []

    " 1) Локальные пресеты из ~/.vim/vimconfigs/colors/*.vim
    for l:file in sort(split(glob(g:theme_presets_dir . '/*.vim'), "\n"))
        if empty(l:file)
            continue
        endif
        let l:name = fnamemodify(l:file, ':t:r')
        call add(l:preset_items, {
                    \ 'name': l:name,
                    \ 'label': '[preset] ' . l:name,
                    \ 'type': 'preset',
                    \ 'value': l:file
                    \ })
    endfor
    call sort(l:preset_items, 's:CompareThemeByName')

    " 2) Все доступные colorscheme из runtimepath (включая plugin темы)
    let l:scheme_items = []
    let l:scheme_map = {}
    for l:path in split(globpath(&runtimepath, 'colors/*.vim'), "\n")
        if empty(l:path)
            continue
        endif
        let l:name = fnamemodify(l:path, ':t:r')
        let l:scheme_map[l:name] = 1
    endfor
    for l:name in sort(keys(l:scheme_map))
        call add(l:scheme_items, {
                    \ 'name': l:name,
                    \ 'label': '[scheme] ' . l:name,
                    \ 'type': 'scheme',
                    \ 'value': l:name
                    \ })
    endfor
    call sort(l:scheme_items, 's:CompareThemeByName')

    " Группы идут в порядке [preset], затем [scheme], внутри каждой сортировка по алфавиту.
    return l:preset_items + l:scheme_items
endfunction

" === Применить тему и записать выбор в state-файл ===
function! s:ApplyThemeItem(item) abort
    try
        call s:ApplyTheme(a:item.type, a:item.value)
        call s:SaveThemeSelection(a:item)

        redraw!
        echom 'Тема применена: ' . a:item.label
    catch
        echohl ErrorMsg
        echom 'Не удалось применить тему: ' . a:item.label
        echohl None
    endtry
endfunction

" === Интерактивный выбор темы по номеру ===
function! SelectThemeInteractive() abort
    let l:items = s:GetThemeOptions()
    if empty(l:items)
        echohl WarningMsg | echom 'Темы не найдены' | echohl None
        return
    endif

    echo 'Выберите тему:'
    for l:i in range(len(l:items))
        echo (l:i + 1) . '. ' . l:items[l:i].label
    endfor

    let l:choice = input('Номер: ')
    if l:choice !~ '^\d\+$'
        echohl WarningMsg | echom 'Неверный ввод' | echohl None
        return
    endif

    let l:index = str2nr(l:choice) - 1
    if l:index < 0 || l:index >= len(l:items)
        echohl WarningMsg | echom 'Неверный номер' | echohl None
        return
    endif

    call s:ApplyThemeItem(l:items[l:index])
endfunction

" === Автоприменение сохраненной темы при старте Vim ===
function! ApplyStartupTheme() abort
    if filereadable(g:theme_state_file)
        try
            execute 'source ' . fnameescape(g:theme_state_file)
            if exists('g:last_theme_type') && exists('g:last_theme_value')
                call s:ApplyTheme(g:last_theme_type, g:last_theme_value)
                return
            endif
        catch
        endtry
    endif

    let l:fallback = expand('~/.vim/vimconfigs/colors/fallout.vim')
    if filereadable(l:fallback)
        execute 'source ' . fnameescape(l:fallback)
    endif
endfunction

" === ШРИФТЫ ===
let g:font_presets = get(g:, 'font_presets', [
            \ 'Fixedsys\ Excelsior\ 3.01:h14',
            \ 'JetBrains\ Mono:h14',
            \ 'SF\ Mono:h14',
            \ 'Menlo:h14',
            \ 'Monaco:h14',
            \ 'Cascadia\ Code:h14',
            \ 'FiraCode\ Nerd\ Font:h14',
            \ 'Hack\ Nerd\ Font:h14',
            \ 'Iosevka\ Nerd\ Font:h14'
            \ ])

if exists('+guifont') && !empty(&guifont) && index(g:font_presets, &guifont) < 0
    call insert(g:font_presets, &guifont, 0)
endif

" === Интерактивный выбор GUI-шрифта ===
function! SelectFontInteractive() abort
    if !has('gui_running')
        echohl WarningMsg
        echom 'В терминальном Vim шрифт меняется в настройках терминала, не внутри Vim.'
        echohl None
        return
    endif

    if !exists('+guifont')
        echohl WarningMsg | echom 'Текущий Vim не поддерживает guifont.' | echohl None
        return
    endif

    let l:items = copy(g:font_presets)
    if empty(l:items)
        echohl WarningMsg | echom 'Список шрифтов пуст' | echohl None
        return
    endif

    echo 'Выберите шрифт:'
    for l:i in range(len(l:items))
        let l:label = substitute(l:items[l:i], '\\ ', ' ', 'g')
        echo (l:i + 1) . '. ' . l:label
    endfor

    let l:choice = input('Номер: ')
    if l:choice !~ '^\d\+$'
        echohl WarningMsg | echom 'Неверный ввод' | echohl None
        return
    endif

    let l:index = str2nr(l:choice) - 1
    if l:index < 0 || l:index >= len(l:items)
        echohl WarningMsg | echom 'Неверный номер' | echohl None
        return
    endif

    try
        execute 'set guifont=' . l:items[l:index]
        redraw!
        echom 'Шрифт применен: ' . substitute(l:items[l:index], '\\ ', ' ', 'g')
    catch
        echohl ErrorMsg
        echom 'Не удалось применить шрифт. Проверьте, установлен ли он в системе.'
        echohl None
    endtry
endfunction
