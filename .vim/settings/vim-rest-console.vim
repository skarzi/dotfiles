" VIM-REST-CONSOLE CONFIG
let g:vrc_set_default_mapping=0
let g:vrc_auto_format_response_enabled=1
let g:vrc_syntax_highlight_response=1
let b:vrc_response_default_content_type='application/json'
let g:vrc_curl_opts = {
\  '-i': '',
\ }
nnoremap <leader>R :call VrcQuery()<CR>
" END VIM-REST-CONSOLE CONFIG
