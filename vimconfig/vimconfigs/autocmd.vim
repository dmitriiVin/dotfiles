" Автоматически обновлять NERDTree при сохранении файлов
autocmd BufWritePost * if exists(':NERDTreeRefreshRoot') | NERDTreeRefreshRoot | endif

" clang-format: всегда искать ближайший .clang-format от текущего файла.
function! s:ClangFormatCurrentBuffer() abort
    if !executable('clang-format') || !&modifiable || &readonly
        return
    endif

    let l:global_cfg = expand('~/.clang-format')
    if empty(l:global_cfg) || !filereadable(l:global_cfg)
        return
    endif

    let l:view = winsaveview()
    let l:cmd = 'clang-format --style=file --fallback-style=Microsoft --assume-filename=' . shellescape(l:global_cfg)
    silent! undojoin | silent! execute '%!' . l:cmd
    call winrestview(l:view)
endfunction

augroup VimConfigClangFormat
    autocmd!
    autocmd FileType c,cpp,cc,cxx,h,hpp,hh,hxx setlocal formatprg=clang-format\ --style=file\ --fallback-style=Microsoft\ --assume-filename=~/.clang-format
    autocmd BufWritePre *.c,*.cc,*.cpp,*.cxx,*.h,*.hh,*.hpp,*.hxx call s:ClangFormatCurrentBuffer()
augroup END

" Отключить все клавиши создания/открытия файлов в NERDTree
autocmd FileType nerdtree nnoremap <buffer> <C-o> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-e> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-p> <nop>
autocmd FileType nerdtree nnoremap <buffer> <C-Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <M-o> <nop>

autocmd FileType nerdtree nnoremap <buffer> <C-n> :call CreateFileOrDirectoryInNERDTree()<CR>
autocmd FileType nerdtree nnoremap <buffer> <C-d> :call DeleteFileOrDirectory()<CR>

" Автозапуск NERDTree при открытии Vim без файлов
autocmd StdinReadPre * let s:std_in=1
autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree | endif

" === Quickfix как монитор: открыт на старте, без перехвата фокуса ===
augroup QuickfixMonitor
    autocmd!
    autocmd VimEnter,BufEnter * call s:AutoOpenQuickfixMonitor()
augroup END

" === Найти рабочее окно-якорь (не NERDTree и не quickfix) ===
function! s:GetQuickfixAnchorWinId() abort
    let l:current_win = win_getid()
    if &buftype !=# 'quickfix' && &filetype !=# 'nerdtree'
        return l:current_win
    endif

    for l:winnr in range(1, winnr('$'))
        let l:bufnr = winbufnr(l:winnr)
        if getbufvar(l:bufnr, '&buftype') !=# 'quickfix' && getbufvar(l:bufnr, '&filetype') !=# 'nerdtree'
            return win_getid(l:winnr)
        endif
    endfor

    return -1
endfunction

" === Открыть quickfix в колонке кода и вернуть фокус ===
function! OpenQuickfixMonitor() abort
    let l:origin_win = win_getid()
    let l:anchor_win = s:GetQuickfixAnchorWinId()
    if l:anchor_win < 0
        return
    endif

    if l:origin_win != l:anchor_win
        silent! call win_gotoid(l:anchor_win)
    endif

    execute 'silent! belowright copen ' . get(g:, 'quickfix_monitor_height', 8)

    if l:origin_win > 0
        silent! call win_gotoid(l:origin_win)
    endif
endfunction

" === Автооткрытие quickfix-монитора, если окно еще не создано ===
function! s:AutoOpenQuickfixMonitor() abort
    if !empty(filter(getwininfo(), 'v:val.quickfix'))
        return
    endif

    call OpenQuickfixMonitor()
endfunction

" === Автообновление clangd/diagnostics при изменении compile_commands.json ===
let s:last_compile_commands_sig = ''
if exists('*timer_stop') && exists('s:compile_commands_watch_timer') && s:compile_commands_watch_timer > 0
    call timer_stop(s:compile_commands_watch_timer)
endif
let s:compile_commands_watch_timer = -1

" === Путь к compile_commands.json в текущем workspace ===
function! s:GetCompileCommandsPath() abort
    return fnamemodify(getcwd(), ':p') . 'compile_commands.json'
endfunction

" === Собрать сигнатуру compile_commands.json (включая target для symlink) ===
function! s:GetCompileCommandsSignature() abort
    let l:path = s:GetCompileCommandsPath()
    let l:path_type = getftype(l:path)
    let l:path_readable = filereadable(l:path)
    let l:path_mtime = getftime(l:path)
    let l:target_path = l:path_type ==# 'link' ? resolve(l:path) : l:path
    let l:target_readable = filereadable(l:target_path)
    let l:target_mtime = getftime(l:target_path)

    return l:path
                \ . '|type=' . l:path_type
                \ . '|readable=' . l:path_readable
                \ . '|mtime=' . l:path_mtime
                \ . '|target=' . l:target_path
                \ . '|target_readable=' . l:target_readable
                \ . '|target_mtime=' . l:target_mtime
endfunction

" === Точечное обновление CoC-диагностики ===
function! s:RefreshDiagnosticsNow(timer) abort
    if !exists('*CocAction')
        return
    endif
    silent! call CocAction('diagnosticRefresh')
endfunction

" === Безопасный запуск CoC-команды по имени ===
function! s:CocRunCommandIfExists(command_name) abort
    if !exists('*CocAction')
        return 0
    endif

    let l:commands = []
    try
        let l:commands = CocAction('commands')
    catch
        return 0
    endtry

    if index(l:commands, a:command_name) < 0
        return 0
    endif

    try
        call CocAction('runCommand', a:command_name)
        return 1
    catch
        return 0
    endtry
endfunction

" === Перезапустить CoC/LSP (или fallback на команды расширений) ===
function! s:RestartCocNow() abort
    if exists(':CocRestart')
        silent! CocRestart
        return
    endif

    if exists('*CocAction')
        call s:CocRunCommandIfExists('workspace.reloadProjects')
        call s:CocRunCommandIfExists('clangd.restart')
    endif
endfunction

" === Проверить изменения compile_commands и обновить диагностику ===
function! s:TrackCompileCommands() abort
    let l:sig = s:GetCompileCommandsSignature()

    if empty(s:last_compile_commands_sig)
        let s:last_compile_commands_sig = l:sig
        if exists('*timer_start')
            call timer_start(250, function('s:RefreshDiagnosticsNow'))
        else
            call s:RefreshDiagnosticsNow(0)
        endif
        return
    endif

    if l:sig ==# s:last_compile_commands_sig
        return
    endif

    let s:last_compile_commands_sig = l:sig

    call s:RestartCocNow()

    if exists('*timer_start')
        call timer_start(600, function('s:RefreshDiagnosticsNow'))
    else
        call s:RefreshDiagnosticsNow(0)
    endif
endfunction

" === Callback таймера для watcher-а compile_commands ===
function! s:CompileCommandsWatchTick(timer) abort
    call s:TrackCompileCommands()
endfunction

" === Старт фонового watcher-а compile_commands.json ===
function! s:StartCompileCommandsWatcher() abort
    call s:TrackCompileCommands()

    if !exists('*timer_start')
        return
    endif

    if exists('s:compile_commands_watch_timer') && s:compile_commands_watch_timer > 0
        call timer_stop(s:compile_commands_watch_timer)
    endif

    " Периодический polling чтобы отслеживать удаление/появление build без редактирования файла.
    let s:compile_commands_watch_timer = timer_start(2000, function('s:CompileCommandsWatchTick'), {'repeat': -1})
endfunction

augroup CompileCommandsWatcher
    autocmd!
    autocmd VimEnter * call s:StartCompileCommandsWatcher()
    autocmd BufEnter,FocusGained,CursorHold * call s:TrackCompileCommands()
    if exists('##DirChanged')
        autocmd DirChanged * call s:TrackCompileCommands()
    endif
augroup END

" === Универсальное автообновление CoC-диагностики для всех языков ===
augroup CocDiagnosticsLiveRefresh
    autocmd!
    autocmd BufEnter,BufWritePost,InsertLeave,FocusGained * if exists('*CocActionAsync') | silent! call CocActionAsync('diagnosticRefresh') | endif
augroup END

" === Авто-закрытие quickfix при :q или :q! ===
augroup AutoCloseQuickfix
    autocmd!
    " Перед выходом из любого окна закрываем quickfix, если оно открыто
    autocmd QuitPre * if &buftype !=# 'quickfix' | silent! cclose | endif
augroup END

" Закрыть Vim если остался только NERDTree
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Отключить Tab/S-Tab в NERDTree чтобы не переключались буферы
autocmd FileType nerdtree nnoremap <buffer> <Tab> <nop>
autocmd FileType nerdtree nnoremap <buffer> <S-Tab> <nop>
autocmd FileType nerdtree nnoremap <silent><buffer> <Tab><Left> <C-w>h
autocmd FileType nerdtree nnoremap <silent><buffer> <Tab><Right> <C-w>l
autocmd FileType nerdtree nnoremap <silent><buffer> <Tab><Up> <C-w>k
autocmd FileType nerdtree nnoremap <silent><buffer> <Tab><Down> <C-w>j
autocmd FileType nerdtree nnoremap <silent><buffer> <S-Left> <C-w>h
autocmd FileType nerdtree nnoremap <silent><buffer> <S-Right> <C-w>l
autocmd FileType nerdtree nnoremap <silent><buffer> <S-Up> <C-w>k
autocmd FileType nerdtree nnoremap <silent><buffer> <S-Down> <C-w>j

autocmd FileType nerdtree setlocal nobuflisted signcolumn=no
autocmd FileType qf setlocal nobuflisted signcolumn=no
autocmd FileType qf nnoremap <buffer> <Tab> <nop>
autocmd FileType qf nnoremap <buffer> <S-Tab> <nop>

augroup GitCloseMapping
    autocmd!
    autocmd FileType git,gitcommit,gitrebase,gitconfig nnoremap <buffer> <C-q> :call GitSaveAndClose()<CR>
augroup END

" === Привязка функции NERDTreeCD к клавише i внутри NERDTree ===
autocmd FileType nerdtree nnoremap <buffer> i :call NERDTreeCD()<CR>
