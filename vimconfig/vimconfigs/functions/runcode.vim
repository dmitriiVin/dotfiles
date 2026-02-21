" ==== run code function ===
function! RunCode()
    let filename = expand('%')  " получаем имя файла
    let basename = expand('%:r') " получаем имя без расширения
    
    " Проверяем что файл существует
    if empty(filename)
        echo "No file to run"
        return
    endif
    
    if &filetype == 'cpp'
        execute '!clang++ -std=c++17 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'c'
        execute '!clang -std=c99 -O2 -Wall' filename '-o' basename '&& ./' . basename
    elseif &filetype == 'python'
        execute '!python' filename
    elseif &filetype == 'javascript'
        execute '!node' filename
    elseif &filetype == 'pascal'
        execute '!fpc' filename '&& ./' . basename
    elseif &filetype == 'sh' || &filetype == 'bash'
        " Для shell скриптов
        if !executable(filename)
            execute '!chmod +x' filename '&& ./' . filename
        else
            execute '!./' . filename
        endif
    else
        " Пытаемся запустить как бинарный файл
        if executable(filename)
            execute '!./' . filename
        else
            echo "Unsupported file type:" &filetype
        endif
    endif
endfunction