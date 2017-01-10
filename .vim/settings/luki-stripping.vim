function! <SID>strip_trailling_whitespaces()
    " Save last search and cursor position
    let _s=@/
    let l = line(".")
    let c = col(".")
    " Strip
    %s/\s\+$//e
    " Clean up: restore previous search history and cursor position
    let @/=_s
    call cursor(l, c)
endfunction

nnoremap <silent> <leader>s :call <SID>strip_trailling_whitespaces()<CR>

if has("autocmd")
    autocmd BufWritePre *.py,*.js,*c,*cpp,*.pl,*html,*.css,*.scss :call <SID>strip_trailling_whitespaces()
endif
