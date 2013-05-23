if exists("g:vim_redis_loaded")
  finish
endif
let g:vim_redis_loaded = 1

let s:result_win = 0

function! vim_redis#quit()
  if bufexists("[vim-redis]")
    execute s:result_win . "wincmd w"
    execute ":q"
  endif
endfunction

function! vim_redis#execute(...) range
  let command = '!cat /tmp/vim-redis | grep -v "^$" | FAKETTY=1 redis-cli'

  if exists('a:1')
    let command = command . ' -h ' . a:1
  elseif exists('g:vim_redis_host')
    let command = command . ' -h ' . g:vim_redis_host
  endif

  if exists('a:2')
    let command = command . ' -p ' . a:2
  elseif exists('g:vim_redis_port')
    let command = command . ' -p ' . g:vim_redis_port
  endif

  silent redir! > /tmp/vim-redis
  let auth = exists('a:3') ? a:3 : (exists('g:vim_redis_auth') ? g:vim_redis_auth : '')
  if !empty(auth)
    silent echo 'auth ' . auth
    let command = command . " | tail -n+2"
  endif

  let win = winnr()
  for line in range(a:firstline, a:lastline)
    let cmd = substitute(getline(line), '^\s*redis.\{-}>\s*', '', '')
    if cmd !~ '^OK' && cmd =~ '^\s*[a-zA-Z]'
      silent echo cmd
    endif
  endfor
  silent redir END

  if !bufexists("[vim-redis]")
    botright new
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    setf redis
    execute "f [vim-redis]"
    let s:result_win = winnr()
  else
    execute s:result_win . "wincmd w"
    setlocal modifiable
  endif

  if exists("g:vim_redis_paste_command") && g:vim_redis_paste_command
    let line = line('$') - 1
    execute "silent ".line."read !cat /tmp/vim-redis | grep -v '^$'"
  endif
  let line = line('$') - 1
  execute "silent ".line."read ".command

  normal G
  setlocal nomodifiable
  execute win . "wincmd w"
endfunction
