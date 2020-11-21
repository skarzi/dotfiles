function! <SID>strip_trailling_whitespaces()
    " Save last search and cursor position
    let s:_s=@/
    let s:l=line('.')
    let s:c=col('.')
    " Strip
    " cursor position is reverted back in next commands
    " vint: -ProhibitCommandRelyOnUser -ProhibitCommandWithUnintendedSideEffect
    %s/\s\+$//e
    " vint: +ProhibitCommandRelyOnUser +ProhibitCommandWithUnintendedSideEffect
    " Clean up: restore previous search history and cursor position
    let @/=s:_s
    call cursor(s:l, s:c)
endfunction

nnoremap <silent> <leader>s :call <SID>strip_trailling_whitespaces()<CR>

if has('autocmd')
    augroup vimrc_autocmds
        autocmd BufWritePre *.py,*.js,*.c,*.cpp,*.pl,*.vue,*html,*.css,*.scss :call <SID>strip_trailling_whitespaces()
    augroup END
endif
