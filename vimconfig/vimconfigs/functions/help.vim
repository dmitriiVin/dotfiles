" === ЗАКРЫТЬ СПРАВКУ И ВЕРНУТЬСЯ В ПРЕДЫДУЩИЙ БУФЕР ===
function! s:CloseVimCommandsHelp() abort
    let l:prev_buf = get(b:, 'vimconfig_help_prev_buf', -1)

    if l:prev_buf > 0 && bufexists(l:prev_buf)
        execute 'buffer ' . l:prev_buf
    else
        bdelete!
    endif
endfunction

" === ПРОВЕРИТЬ, ЧТО ОКНО ПОДХОДИТ ДЛЯ КОДА ===
function! s:IsCodeWindow(winid) abort
    if a:winid <= 0
        return 0
    endif

    let l:bufnr = winbufnr(a:winid)
    if l:bufnr <= 0
        return 0
    endif

    let l:buftype = getbufvar(l:bufnr, '&buftype')
    let l:filetype = getbufvar(l:bufnr, '&filetype')

    return l:buftype ==# '' && l:filetype !=# 'nerdtree'
endfunction

" === НАЙТИ ЛУЧШЕЕ ОКНО С КОДОМ В ТЕКУЩЕЙ ВКЛАДКЕ ===
function! s:FindCodeWindowInCurrentTab() abort
    for l:wininfo in getwininfo()
        if l:wininfo.tabnr == tabpagenr() && s:IsCodeWindow(l:wininfo.winid)
            return l:wininfo.winid
        endif
    endfor

    return -1
endfunction

" === ОТКРЫТЬ ПОДРОБНУЮ СПРАВКУ ПО КОНФИГУРАЦИИ ===
function! ShowVimCommandsHelp() abort
    let l:target_win = win_getid()
    if !s:IsCodeWindow(l:target_win)
        let l:target_win = s:FindCodeWindowInCurrentTab()
        if l:target_win > 0
            call win_gotoid(l:target_win)
        endif
    endif

    let l:prev_buf = bufnr('%')
    let l:help_lines = [
                \ 'VimConfig Help',
                \ '============',
                \ '',
                \ 'Быстрый выход: нажмите Esc чтобы закрыть справку.',
                \ '',
                \ 'Лидер-клавиша: \',
                \ '',
                \ 'Базовые действия:',
                \ '  Ctrl+S          - сохранить файл',
                \ '  Ctrl+B          - закрыть текущий буфер (перейти на предыдущий, удалить текущий)',
                \ '  Tab / Shift+Tab - переключение по рабочим буферам',
                \ '  Tab+стрелки     - переход между окнами (код/NERDTree/quickfix)',
                \ '  Shift+стрелки   - быстрый переход между окнами',
                \ '',
                \ 'Поиск и редактирование:',
                \ '  Ctrl+F          - поиск',
                \ '  Ctrl+H          - убрать подсветку поиска',
                \ '  Ctrl+A          - выделить все',
                \ '  Ctrl+D / Ctrl+K - удалить строку/выделение',
                \ '  \c              - комментировать/раскомментировать строку',
                \ '',
                \ 'Буферы и файлы:',
                \ '  \x              - закрыть текущий буфер',
                \ '  \bd             - закрыть текущий буфер',
                \ '  \bo             - закрыть все буферы, кроме текущего',
                \ '  \bl             - список буферов',
                \ '  Ctrl+O          - открыть файл (path completion)',
                \ '  Ctrl+E          - открыть файл из директории текущего файла',
                \ '  Alt+O           - безопасное открытие файла',
                \ '',
                \ 'NERDTree:',
                \ '  F1              - открыть/закрыть NERDTree',
                \ '  F4              - обновить NERDTree',
                \ '  Ctrl+N          - создать файл/папку в NERDTree',
                \ '  Ctrl+D          - удалить файл/папку в NERDTree',
                \ '',
                \ 'CMake:',
                \ '  F3              - удалить папку build текущего CMake-проекта',
                \ '  F6              - генерация CMake',
                \ '  F7              - сборка (автогенерация при необходимости)',
                \ '  F8              - выбор исполняемого файла',
                \ '  F9              - запуск выбранного файла',
                \ '  F10             - переключить Debug/Release',
                \ '  F12             - создать/открыть CMakeLists.txt из NERDTree',
                \ '  \ru             - быстрый цикл: generate+build+auto-select+run',
                \ '  \bt             - показать текущий build type',
                \ '',
                \ 'Локальные версии кода (Debug/Release):',
                \ '  F10             - переключить build type и сразу подменить кодовую версию',
                \ '  Профили кода    - хранятся в .vim-code-profiles/debug и .vim-code-profiles/release',
                \ '  Поведение       - при F10 текущая версия сохраняется, целевая загружается',
                \ '',
                \ 'Диагностика и quickfix:',
                \ '  Ctrl+W          - открыть quickfix-монитор',
                \ '  Ctrl+Q          - закрыть quickfix',
                \ '  \qn / \qp       - следующая/предыдущая ошибка',
                \ '  \qf / \ql       - первая/последняя ошибка',
                \ '',
                \ 'Git/Fugitive:',
                \ '  \gs             - Git status',
                \ '  \gc             - Git commit',
                \ '  \gp             - Git push',
                \ '  \gl             - Git pull',
                \ '  \gb             - переключить ветку (интерактивно)',
                \ '  \gn             - создать и переключить новую ветку',
                \ '  \go             - открыть текущий файл/репозиторий в браузере',
                \ '  \gv             - переключить Git worktree',
                \ '  \gm             - настроить Debug/Release ветки',
                \ '  \gd / \gr       - быстро перейти в Debug/Release ветку',
                \ '',
                \ 'Темы и шрифты:',
                \ '  \th             - выбрать и применить тему (с сохранением между запусками)',
                \ '  \ff             - выбрать GUI-шрифт (в терминале меняется в настройках терминала)',
                \ '',
                \ 'Служебное:',
                \ '  Ctrl+Shift+R    - полный рестарт Vim',
                \ '  \h              - открыть эту справку',
                \ '  Esc             - закрыть справку и вернуться в код',
                \ '',
                \ 'Примечание:',
                \ '  Справка относится к вашему текущему vimconfig (mappings/options/functions).',
                \ ]

    " Открываем справку в текущем окне (без split).
    silent! hide enew
    setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted
    setlocal filetype=help
    let b:vimconfig_help_prev_buf = l:prev_buf

    nnoremap <silent><buffer> <Esc> :call <SID>CloseVimCommandsHelp()<CR>

    call setline(1, l:help_lines)
    setlocal nomodifiable readonly
    normal! gg
endfunction
