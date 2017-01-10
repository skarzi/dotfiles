let vim_settings="~/.vim/settings"

for fpath in split(globpath(vim_settings, '*.vim'), '\n')
  exe 'source' fpath
endfor
