" === СОЧЕТАНИЯ КЛАВИШ ===

" Ctrl + S - сохранить файл
inoremap <silent> <C-s> <Esc>:w<CR>a
nnoremap <silent> <C-s> :w<CR>
vnoremap <silent> <C-s> <Esc>:w<CR>gv

" " Ctrl + X - закрыть текущий файл в буфере
nnoremap <C-x> :bp\|bd #<CR>
nnoremap <leader>x :bp\|bd #<CR>

" " Ctrl + W - закрыть текущее сплит окно
" vnoremap <C-w> :q<CR>
" inoremap <C-w> :q<CR>
" nnoremap <C-w> :q<CR>

" Ctrl + S - сохранить
nnoremap <silent> <C-S-s> :w<CR>
inoremap <silent> <C-S-s> <Esc>:w<CR>a
vnoremap <silent> <C-S-s> <Esc>:w<CR>gv
" Ctrl + C - копировать выделенный текст в системный буфер
vnoremap <C-c> "+y
inoremap <C-c> "+y
nnoremap <C-c> "+y

" Ctrl + A - выделить весь текст в файле
nnoremap <C-a> ggVG
vnoremap <C-a> ggVG
inoremap <C-a> ggVG

" Ctrl + D — удалить текущую строку
nnoremap <C-d> dd
inoremap <C-d> <Esc>ddi
vnoremap <C-d> d

" Ctrl + Z - отменить предыдущее действие
nnoremap <C-z> u
vnoremap <C-z> u
inoremap <C-z> <C-o>u

" Ctrl + F - поиск по файлу
nnoremap <C-f> /
inoremap <C-f> <Esc>/

" Ctrl + H - убрать подсветку результатов поиска
nnoremap <C-h> :nohlsearch<CR>

" Ctrl + N - создать новый файл
nnoremap <C-n> :call CreateNewFile()<CR>

" Tab - переключение между рабочими буферами (без NERDTree/quickfix)
function! s:IsWorkBuffer() abort
    return &buftype ==# '' && &filetype !=# 'nerdtree'
endfunction

" Переключить рабочий буфер вперед/назад
function! s:CycleWorkBuffer(step) abort
    if !s:IsWorkBuffer()
        return
    endif

    if a:step > 0
        silent! bnext
    else
        silent! bprevious
    endif
endfunction

nnoremap <silent> <Tab> :call <SID>CycleWorkBuffer(1)<CR>
nnoremap <silent> <S-Tab> :call <SID>CycleWorkBuffer(-1)<CR>

" Tab + стрелки - переход между окнами (NERDTree/код/quickfix)
nnoremap <silent> <Tab><Left> <C-w>h
nnoremap <silent> <Tab><Right> <C-w>l
nnoremap <silent> <Tab><Up> <C-w>k
nnoremap <silent> <Tab><Down> <C-w>j

" Shift + стрелки - быстрая навигация по окнам с удержанием Shift
nnoremap <silent> <S-Left> <C-w>h
nnoremap <silent> <S-Right> <C-w>l
nnoremap <silent> <S-Up> <C-w>k
nnoremap <silent> <S-Down> <C-w>j

" Удалить текущую строку - Ctrl + K
nnoremap <C-k> dd
inoremap <C-k> <Esc>ddi
vnoremap <C-k> d

" F2 - переименовать текущий файл
nnoremap <F2> :call RenameFile()<CR>

" F3 - удалить папку build для текущего CMake-проекта
nnoremap <F3> :call CMakeDeleteBuildDir()<CR>

" F5 - запуск кода (зависит от типа файла)
nnoremap <F5> :call RunCode()<CR>

" === КОМАНДЫ ДЛЯ CMAKE (ЛОКАЛЬНЫЕ ПО CMakeLists.txt) ===

" F6 - Генерация CMake в текущей директории CMakeLists.txt
nnoremap <F6> :call CMakeGenerateFixed()<CR>

" F7 - Сборка проекта
nnoremap <F7> :call CMakeBuildFixed()<CR>

" F8 - Выбор таргета из текущего Debug
nnoremap <F8> :call CMakeSelectTargetInteractive()<CR>

" F9 - Запуск выбранного таргета
nnoremap <F9> :call CMakeRunFixed()<CR>

" F10 - переключение с debug на Release и наоборот
nnoremap <silent> <F10> <Cmd>call CMakeToggleBuildType()<CR>

" F12 - Создание/открытие CMakeLists.txt в папке NERDTree без закрытия NERDTree
nnoremap <F12> :call CreateCMakeListsInNERDTree()<CR>

" \ + R + U - Быстрый запуск: генерация + сборка + запуск первого исполняемого файла
nnoremap <leader>ru :call CMakeQuickRun()<CR>

" \ + B + T ПОКАЗАТЬ ТЕКУЩИЙ ТИП СБОРКИ (DEBUG / RELEASE)
nnoremap <leader>bt :call ShowCMakeBuildType()<CR>

" \ + T + H - выбрать и применить тему
nnoremap <leader>th :call SelectThemeInteractive()<CR>

" \ + F + F - выбрать и применить шрифт
nnoremap <leader>ff :call SelectFontInteractive()<CR>

" \ + H - открыть встроенную справку по командам конфигурации
nnoremap <leader>h :call ShowVimCommandsHelp()<CR>

" === УПРАВЛЕНИЕ NERDTREE И БУФЕРАМИ ===

" F1 - открыть/закрыть NERDTree
nnoremap <F1> :NERDTreeToggle<CR>

" F4 - обновить NERDTree (чтобы видеть новые файлы)
nnoremap <F4> :NERDTreeRefreshRoot<CR>

" Ctrl + N - создать файл или папку в текущей папке NERDTree
nnoremap <C-n> :call CreateFileOrDirectoryInNERDTree()<CR>

" Ctrl + D - удалить файл/папку в NERDTree
nnoremap <C-d> :call DeleteFileOrDirectory()<CR>

" Ctrl + B - закрыть текущий файл в буфере
nnoremap <C-b> :bp\|bd #<CR>

" === РАБОТА С ФАЙЛАМИ И ПУТЯМИ ===

" Ctrl + O - открыть файл с началом в текущей директории
nnoremap <C-o> :e ./<C-d>
inoremap <C-o> <Esc>:e ./<C-d>

" Ctrl + E - быстрое открытие файла в текущей директории
nnoremap <C-e> :e <C-R>=expand("%:p:h") . "/" <CR>
inoremap <C-e> <Esc>:e <C-R>=expand("%:p:h") . "/" <CR>

" Ctrl + P - поиск файла по имени из текущей директории
nnoremap <C-p> :find *
inoremap <C-p> <Esc>:find *

" Alt+O для безопасного открытия (только в рабочей области)
nnoremap <M-o> :call SafeEdit()<CR>
inoremap <M-o> <Esc>:call SafeEdit()<CR>

" Tab для автодополнения путей
cnoremap <expr> <Tab> TerminalTabComplete()

" Shift+Tab для обратного перебора
cnoremap <expr> <S-Tab> wildmenumode() ? "\<Up>" : "\<S-Tab>"

" Ctrl+Space для показа всех вариантов
cnoremap <C-Space> <C-d>

" Alt+O для безопасного открытия (только в рабочей области)
nnoremap <M-o> :call SafeEdit()<CR>
inoremap <M-o> <Esc>:call SafeEdit()<CR>

" === ВАЖНЫЕ МАПИНГИ КОТОРЫЕ НЕ ЗАБИНЖЕНЫ ===

" Быстрое переключение между последними файлами (только в рабочей области)
" nnoremap <C-Tab> :call SafeBufferSwitch()<CR>
" inoremap <C-Tab> <Esc>:call SafeBufferSwitch()<CR>

" Показать текущий выбранный таргет
nnoremap <leader>ct :echo "Current target: " . (empty(g:cmake_selected_target) ? "none" : g:cmake_selected_target)<CR>

" Показать список всех открытых буферов
nnoremap <leader>bl :ls<CR>:b<space>

" Двойной клик левой кнопкой мыши → перейти в Insert mode
nnoremap <2-LeftMouse> <LeftMouse>i

" Закрыть текущий буфер
nnoremap <leader>bd :bd<CR>

" Закрыть все буферы кроме текущего
nnoremap <leader>bo :%bd\|e#<CR>

" Быстрое переключение между последними файлами (уже есть)
nnoremap <C-Tab> :b#<CR>

" Быстрая навигация по директориям
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>  " Перейти в директорию текущего файла

" Показать текущий путь
nnoremap <leader>pwd :pwd<CR>

" Создать новую директорию
nnoremap <leader>md :!mkdir -p

" Открыть проводник в текущей директории
nnoremap <leader>ex :!open .<CR>

" === АВТОЗАВЕРШЕНИЕ СКОБОК ===
inoremap " ""<Left>
inoremap ' ''<Left>
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>

" Умное автозакрытие (только если следующая скобка не открыта)
inoremap <expr> " strpart(getline('.'), col('.')-1, 1) == '"' ? "\<Right>" : '""<Left>'
inoremap <expr> ' strpart(getline('.'), col('.')-1, 1) == "'" ? "\<Right>" : "''<Left>"

" \ + C для комментирования/раскомментирования кода
noremap <leader>c :Commentary<CR>
inoremap <leader>c <Esc>:Commentary<CR>a

" Tab для автодополнения
inoremap <expr> <Tab> pumvisible() ? "\<C-y>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

" Enter для подтверждения автодополнения
inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<cr>"

" === ЛОКАЛЬНЫЕ ВЕРСИИ КОДА (GIT) ===

" \ + G + S - Git status в единственном буфере
nnoremap <leader>gs :Git<CR>

" \ + G + C - Git commit в единственном буфере
nnoremap <leader>gc :Git commit<CR>

" \ + G + P - Git push
nnoremap <leader>gp :Git push<CR>

" \ + G + U - Git pull
nnoremap <leader>gl :Git pull<CR>

" \ + G + O - Открыть на GitHub в браузере
nnoremap <leader>go :GBrowse<CR>

" \ + G + B - Переключить Git-ветку (интерактивно)
nnoremap <leader>gb :call GitSwitchBranchInteractive()<CR>

" \ + G + N - Создать и переключить новую Git-ветку
nnoremap <leader>gn :call GitCreateBranchInteractive()<CR>

" \ + G + V - Переключить Git worktree (другая версия кода)
nnoremap <leader>gv :call GitSwitchWorktreeInteractive()<CR>

" \ + G + M - Настроить локальные ветки для Debug/Release
nnoremap <leader>gm :call GitConfigureBuildBranchesInteractive()<CR>

" \ + G + D - Быстро переключить локальную Debug-ветку
nnoremap <leader>gd :call GitSwitchBranchForBuildType('Debug')<CR>

" \ + G + R - Быстро переключить локальную Release-ветку
nnoremap <leader>gr :call GitSwitchBranchForBuildType('Release')<CR>

" \ + G + Shift + D - Запомнить текущую ветку как Debug
nnoremap <leader>gD :call GitBindCurrentBranchToBuildType('Debug')<CR>

" \ + G + Shift + R - Запомнить текущую ветку как Release
nnoremap <leader>gR :call GitBindCurrentBranchToBuildType('Release')<CR>

" ====== QUICKFIX =======

" Открыть/закрыть quickfix
nnoremap <C-w> :call OpenQuickfixMonitor()<CR>
nnoremap <C-q> :cclose<CR>

" Навигация по ошибкам
nnoremap <leader>qn :cnext<CR>
nnoremap <leader>qp :cprev<CR>
nnoremap <leader>qf :cfirst<CR>
nnoremap <leader>ql :clast<CR>


" Ctrl + Shift + R — Полный рестарт Vim
nnoremap <C-S-r> :call RestartVimFull()<CR>
