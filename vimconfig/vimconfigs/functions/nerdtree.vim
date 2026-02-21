" === ФУНКЦИЯ СОЗДАНИЯ ФАЙЛА/ДИРЕКТОРИИ В NERDTREE === 
function! CreateFileOrDirectoryInNERDTree()
    if &filetype == 'nerdtree'
        " Получаем путь к текущему узлу NERDTree
        let current_path = g:NERDTreeFileNode.GetSelected().path.str()
        if empty(current_path)
            echo "Не удалось получить путь"
            return
        endif
        
        " Определяем директорию
        if isdirectory(current_path)
            let target_dir = current_path
        else
            let target_dir = fnamemodify(current_path, ':h')
        endif
        
        " Выбор типа: файл или папка
        let choice = confirm("Создать:", "&AФайл\n&GПапку", 1)
        
        if choice == 1
            " Создание файла
            let new_filename = input('Имя файла (с расширением): ', target_dir . '/')
            if new_filename != ''
                " Создаем файл
                let cmd = 'touch "' . new_filename . '"'
                let output = system(cmd)
                
                if v:shell_error
                    echo "Ошибка при создании файла: " . output
                else
                    echo "Создан файл: " . fnamemodify(new_filename, ':t')
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
            
        elseif choice == 2
            " Создание папки
            let new_dirname = input('Имя папки: ', target_dir . '/')
            if new_dirname != ''
                " Создаем папку
                let cmd = 'mkdir -p "' . new_dirname . '"'
                let output = system(cmd)
                
                if v:shell_error
                    echo "Ошибка при создании папки: " . output
                else
                    echo "Создана папка: " . fnamemodify(new_dirname, ':t')
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
        endif
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction

" === ФУНКЦИЯ УДАЛЕНИЯ ФАЙЛА/ДИРЕКТОРИИ В NERDTREE ===
function! DeleteFileOrDirectory()
    if &filetype == 'nerdtree'
        " Получаем путь к выбранному файлу/папке
        let current_node = g:NERDTreeFileNode.GetSelected()
        if !empty(current_node)
            let path = current_node.path.str()
            let name = current_node.path.getLastPathComponent(1)

            " Подтверждение удаления
            let choice = confirm("Удалить '" . name . "'?", "&Yes\n&No", 2)
            if choice == 1
                " Удаляем файл или папку
                if isdirectory(path)
                    " Удаляем папку рекурсивно
                    let cmd = 'rm -rf "' . path . '"'
                else
                    " Удаляем файл
                    let cmd = 'rm "' . path . '"'
                endif

                " Выполняем удаление
                let output = system(cmd)
                if v:shell_error
                    echo "Ошибка при удалении: " . output
                else
                    echo "Удалено: " . name
                    " Обновляем NERDTree
                    NERDTreeRefreshRoot
                endif
            endif
        else
            echo "Не выбран файл или папка"
        endif
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction

" Создать новый файл в текущей директории с обновлением NERDTree (только в рабочей области)
function! CreateNewFile()
    if &filetype != 'nerdtree'
        let current_dir = expand("%:p:h")
        let new_file = input('New file name: ', current_dir . '/')
        if new_file != ''
            execute 'edit ' . new_file
            execute 'write'
            " Обновляем NERDTree если он открыт
            if exists(':NERDTreeRefreshRoot')
                NERDTreeRefreshRoot
            endif
        endif
    endif
endfunction

" === ФУНКЦИЯ ПЕРЕИМЕНОВАНИЯ ФАЙЛА/ДИРЕКТОРИИ В NERDTREE ===
function! RenameFile()
    if &filetype == 'nerdtree'
        " Получаем выбранный узел
        let current_node = g:NERDTreeFileNode.GetSelected()
        if empty(current_node)
            echo "Не выбран файл или папка"
            return
        endif

        let old_path = current_node.path.str()
        let old_name = current_node.path.getLastPathComponent(1)

        " Ввод нового имени
        let new_name = input('Новое имя для "' . old_name . '": ', old_name)
        if empty(new_name)
            echo "Переименование отменено"
            return
        endif

        " Получаем путь к родительской директории
        let parent_dir = fnamemodify(old_path, ':h')
        let new_path = parent_dir . '/' . new_name

        " Проверка на существование
        if filereadable(new_path) || isdirectory(new_path)
            echo "Файл или папка с таким именем уже существует!"
            return
        endif

        " Выполняем переименование
        let cmd = 'mv "' . old_path . '" "' . new_path . '"'
        let output = system(cmd)

        if v:shell_error
            echo "Ошибка при переименовании: " . output
        else
            echo "Переименовано: " . old_name . " → " . new_name
            " Обновляем NERDTree
            NERDTreeRefreshRoot
        endif
    else
        echo "Эта команда работает только в NERDTree"
    endif
endfunction

" === Функция CD внутрь выбранной директории в NERDTree ===
function! NERDTreeCD()
    if &filetype !=# 'nerdtree'
        echo "Эта команда работает только в NERDTree"
        return
    endif

    " Получаем выбранный узел
    let node = g:NERDTreeFileNode.GetSelected()
    if empty(node)
        echo "Не выбран файл или папка"
        return
    endif

    " Если это директория — переходим в неё
    if isdirectory(node.path.str())
        let dir = node.path.str()
        " Меняем рабочую директорию Vim
        execute 'cd ' . fnameescape(dir)
        " Обновляем NERDTree, чтобы показывалась только эта директория
        execute 'NERDTreeClose'
        execute 'NERDTreeToggle ' . fnameescape(dir)
        echo "📁 Перешли в: " . dir
    else
        echo "Выбранный узел не является директорией"
    endif
endfunction
