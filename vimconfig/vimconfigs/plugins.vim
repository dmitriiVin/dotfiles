" === ПЛАГИНЫ ===
call plug#begin('~/.vim/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'jiangmiao/auto-pairs'

" === THEMES ===
Plug 'morhetz/gruvbox'
Plug 'cormacrelf/vim-colors-github'

" Дополнительные полезные плагины
Plug 'scrooloose/nerdtree'              " Файловый менеджер
Plug 'tpope/vim-commentary'             " Комментирование кода
Plug 'airblade/vim-gitgutter'           " Git статус на полях
Plug 'vim-airline/vim-airline'          " Статус бар
Plug 'vim-airline/vim-airline-themes'   " Темы для статус бара
Plug 'bfrg/vim-cpp-modern'
Plug 'cdelledonne/vim-cmake'           " Основной функционал
Plug 'pboettch/vim-cmake-syntax'       " Подсветка синтаксиса
Plug 'ilyachur/cmake4vim'              " Дополнение и утилиты

" === GIT И GITHUB ИНТЕГРАЦИЯ ===
Plug 'tpope/vim-fugitive'      " Git интеграция
Plug 'tpope/vim-rhubarb'       " GitHub интеграция

call plug#end()

" Цветовая схема ставим после установки всех плагинов
" colorscheme github
set background=dark
