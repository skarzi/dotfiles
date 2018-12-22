let s:vim_settings='~/.vim/settings'

for s:fpath in split(globpath(s:vim_settings, '*.vim'), '\n')
  exe 'source' s:fpath
endfor
