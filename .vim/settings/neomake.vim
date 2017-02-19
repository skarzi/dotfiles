" NEOMAKE CONFIG
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
" let g:syntastic_enable_highlighting = 1
let g:neomake_open_list = 2
let g:neomake_list_height = 3

" python
let g:neomake_python_flake8_maker = {
    \ 'exe': 'flake8',
\ }
let g:neomake_python_enabled_makers = ['flake8']

" javascript
let g:neomake_javascript_eslint_maker = {
    \ 'exe': 'npm run eslint ',
\ }
let g:neomake_javascript_jshint_maker = {
    \ 'exe': 'jshint',
    \ 'errorformat': '%f: line %l\, col %c\, %m',
\ }
let g:neomake_javascript_jscs_maker = {
    \ 'exe': 'jscs',
    \ 'args': ['--no-color', '--preset', 'airbnb', '--reporter', 'inline', '--esnext'],
    \ 'errorformat': '%f: line %l\, col %c\, %m',
\ }
let g:neomake_javascript_enabled_makers = ['jshint', 'eslint', 'jscs']

" html
let g:neomake_html_enabled_makers = ['tidy', 'htmlhint']

" neomake signs
let g:neomake_error_sign = {
    \ 'text': 'E',
    \ 'texthl': 'NeomakeErrorSign',
\ }
let g:neomake_warning_sign = {
    \   'text': 'W',
    \   'texthl': 'NeomakeWarningSign',
\ }
let g:neomake_message_sign = {
    \   'text': '➤',
    \   'texthl': 'NeomakeMessageSign',
\ }
let g:neomake_info_sign = {
    \ 'text': 'I',
    \ 'texthl': 'NeomakeInfoSign',
\ }
" END NEOMAKE CONFIG

