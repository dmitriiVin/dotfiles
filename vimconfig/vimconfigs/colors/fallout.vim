" ================================
" === Fallout Terminal Colors ===
" ================================

if !has("termguicolors")
  set t_Co=256
endif

set termguicolors
set background=dark

" ----------------
" Основной текст (везде #00CC00)
" ----------------
highlight Normal     guifg=#00CC00 guibg=#000000
highlight Comment    guifg=#00CC00 guibg=#000000 gui=italic cterm=italic
highlight Statement  guifg=#00CC00 guibg=#000000
highlight Identifier guifg=#00CC00 guibg=#000000
highlight Constant   guifg=#00CC00 guibg=#000000
highlight Type       guifg=#00CC00 guibg=#000000
highlight String     guifg=#00CC00 guibg=#000000
highlight Number     guifg=#00CC00 guibg=#000000
highlight Function   guifg=#00CC00 guibg=#000000 gui=bold cterm=bold

" ----------------
" Поиск
" ----------------
highlight Search guifg=#000000 guibg=#00CC00

" ----------------
" Курсор
" ----------------
highlight CursorLine   guibg=#001a00
highlight CursorLineNr guifg=#00CC00 guibg=#001a00 gui=bold
highlight LineNr       guifg=#006600 guibg=#000000
set cursorline

" ----------------
" StatusLine
" ----------------
highlight StatusLine   guifg=#00CC00 guibg=#002200 gui=bold cterm=bold
highlight StatusLineNC guifg=#00CC00 guibg=#001a00

" ----------------
" Буферы (очень яркие)
" ----------------
highlight TabLine      guifg=#00FF00 guibg=#001a00 gui=bold cterm=bold
highlight TabLineSel   guifg=#000000 guibg=#00CC00 gui=bold cterm=bold
highlight TabLineFill  guibg=#001100

" ----------------
" Разделители
" ----------------
highlight VertSplit    guifg=#006600 guibg=#000000
highlight WinSeparator guifg=#006600 guibg=#000000
