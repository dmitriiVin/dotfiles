" ================================
" ===      ОСНОВНОЙ ФАЙЛ       ===
" ================================

let g:git_default_remote_url_template = 'https://github.com/{owner}/{repo}.git'
let g:git_auto_create_github_repo = 1
let g:git_auto_create_repo_visibility = 'public'

" === CoC: использовать Node LTS, если найден, иначе системный node ===
if executable('brew')
    let s:node20_prefix = trim(system('brew --prefix node@20 2>/dev/null'))
    if !empty(s:node20_prefix) && executable(s:node20_prefix . '/bin/node')
        let g:coc_node_path = s:node20_prefix . '/bin/node'
    endif
endif

if !exists('g:coc_node_path') && executable('node')
    let g:coc_node_path = exepath('node')
endif

" подключаем авто функции
source ~/.vim/vimconfigs/autocmd.vim

" === Подключаем функции ===
source ~/.vim/vimconfigs/functions/cmake.vim
source ~/.vim/vimconfigs/functions/nerdtree.vim
source ~/.vim/vimconfigs/functions/runcode.vim
source ~/.vim/vimconfigs/functions/terminal.vim
source ~/.vim/vimconfigs/functions/github.vim
source ~/.vim/vimconfigs/functions/coc_russian.vim
source ~/.vim/vimconfigs/functions/help.vim

" === Подключаем бинды ===
source ~/.vim/vimconfigs/mappings.vim

" === подключаем опции ===
source ~/.vim/vimconfigs/options.vim

" === CoC: популярные языки ===
let g:coc_global_extensions = [
            \ 'coc-clangd',
            \ 'coc-json',
            \ 'coc-tsserver',
            \ 'coc-css',
            \ 'coc-yaml',
            \ 'coc-pyright',
            \ 'coc-rust-analyzer',
            \ 'coc-cmake',
            \ 'coc-sh'
            \ ]

" === Подключаем плагины ===
source ~/.vim/vimconfigs/plugins.vim

call ApplyStartupTheme()
