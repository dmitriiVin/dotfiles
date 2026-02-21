" Умное автодополнение путей как в терминале
function! TerminalTabComplete()
    let cmdline = getcmdline()

    " Если вводим путь с / - дополняем как путь
    if cmdline =~ '.*/.*'
        return "\<C-x>\<C-f>"
    " Если команда начинается с :e, :find и т.д. - дополняем файлы
    elseif cmdline =~ '^:\?\(e\|find\|edit\)\s'
        return "\<C-x>\<C-f>"
    " Для других случаев - обычное дополнение
    else
        return "\<C-x>\<C-p>"
    endif
endfunction

" === Безопасное переключение на предыдущий буфер (не из NERDTree) ===
function! SafeBufferSwitch()
    if &filetype != 'nerdtree'
        :b#
    endif
endfunction

" === ФУНКЦИЯ ДЛЯ БЕЗОПАСНОГО ОТКРЫТИЯ ФАЙЛОВ ===
function! SafeEdit()
    if &filetype != 'nerdtree'
        let file_path = input('Open file: ', '', 'file')
        if file_path != ''
            try
                execute 'edit ' . fnameescape(file_path)
            catch
                echo "Error opening file: " . v:exception
            endtry
        endif
    endif
endfunction

" === ПОЛНАЯ ПЕРЕЗАГРУЗКА VIM ===
function! RestartVimFull() abort
    " Сохраняем все файлы
    silent! wall

    " Сохраняем текущую позицию
    let l:session = tempname() . '.vim'

    " Создаём временную сессию
    execute 'mksession! ' . fnameescape(l:session)

    " Перезапускаем Vim и загружаем сессию
    execute 'silent !' . v:progpath . ' -S ' . fnameescape(l:session)

    " Закрываем текущий Vim
    qa!
endfunction
