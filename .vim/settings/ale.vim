scriptencoding utf-8

" ALE CONFIG
" TODO(skarzi): configure ALE to run via Docker
" https://github.com/dense-analysis/ale#5xx-how-can-i-run-linters-or-fixers-via-docker-or-a-vm

let g:ale_lint_on_text_changed = 'never'
let g:ale_lint_on_save = 1
let g:ale_lint_on_enter = 1

let g:ale_open_list = 1
let g:ale_set_loclist = 1
let g:ale_list_window_size = 5

let g:ale_sign_error = '🐛'
let g:ale_sign_warning = '⚠️'
let g:ale_sign_info = 'ℹ️'

nmap <F7> :ALELint<CR>
nmap <F8> :ALEFix<CR>

let g:ale_linter_aliases = {
\    'vue': ['javascript', 'vue'],
\    'jsx': ['css', 'javascript'],
\    'pandoc': ['pandoc', 'markdown'],
\ }

let g:ale_linters = {
\    'vue': ['eslint', 'vls'],
\    'jsx': ['css', 'javascript'],
\    'python': ['bandit', 'flake8', 'mypy', 'pydocstyle', 'ruff'],
\ }
let g:ale_fixers = {
\    '*': ['remove_trailing_lines', 'trim_whitespace'],
\    'python': ['black', 'isort', 'ruff', 'remove_trailing_lines', 'trim_whitespace'],
\ }

" python
" `isort` fixer
nnoremap <Leader>z :<C-U>ALEFix isort<CR>
" END ALE CONFIG
