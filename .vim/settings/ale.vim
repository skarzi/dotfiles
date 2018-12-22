" ALE CONFIG
let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1
let g:ale_lint_on_enter = 1

let g:ale_open_list = 1
let g:ale_set_loclist = 1
let g:ale_list_window_size = 3

" airline
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#ale#error_symbol = 'E:'
let g:airline#extensions#ale#warning_symbol = 'W:'

nmap <F7> :ALELint<CR>

let g:ale_linter_aliases = {
\   'vue': ['vue', 'javascript'],
\ }

let g:ale_linters = {
\     'vue': ['eslint', 'vls'],
\ }

" python
" `isort` fixer
nnoremap <Leader>z :<C-U>ALEFix isort<CR>

" END ALE CONFIG
