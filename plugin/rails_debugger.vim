" Vim plugin for debugging Rails applications
" Maintainer: Anton Astashov (anton at astashov dot net, http://astashov.net)

map <Leader>b  :call Set_breakpoint()<CR>
map <Leader>r  :call Receive_command()<CR>
command! Rdebugger :call s:start_debugger() 


let s:debugger_port = 39767
let s:wrapper_port = 39768
let s:buffer_file = expand('~/.vim/tmp/buffer_debugger124719283457192')


" Init breakpoing signs
hi breakpoint  term=NONE    cterm=NONE    gui=NONE
sign define breakpoint  linehl=breakpoint  text=>>


" Create directory for temporary (buffer) file
call system('mkdir -p ~/.vim/tmp')
call system('touch ~/.vim/tmp/' . s:buffer_file)

" Open file for input debugger commands
exe 'sp ' . s:buffer_file 
exe 'hide'

" When file for input debugger commands is changed (new command is arrived),
" it will process the command
exe 'au FileChangedShell ' . s:buffer_file . ' call Receive_command()'


function! s:start_debugger()
  call system('rdebug-ide -p ' . s:debugger_port . ' -- script/server &')
  call system('ruby ' . expand("~/.vim/bin/debugger.rb") . ' ' . s:debugger_port . ' ' . s:wrapper_port . ' ' . s:buffer_file . ' &')
endfunction


function! Receive_command()
  let cmd = system('cat ' . s:buffer_file)
  if match(cmd, '<breakpoint ') != -1
    call s:command_jump_to_breakpoint(cmd)
  else if match(cmd, '<breakpointAdded ') != -1
    call s:command_set_breackpoint(cmd)
  endif
endfunction


function! Set_breakpoint()
  let line = line(".")
  let file = s:get_filename()
  let message = 'break ' . file . ':' . line
  s:send_message_to_debugger(message)
  :exe ":sign place 2 line=" . line . " name=breakpoint file=" . file
endfunction


function! s:get_filename()
  return bufname("%")
endfunction


function! s:send_message_to_debugger(message)
  call system("ruby -e \"require 'socket'; a = TCPSocket.open('localhost', 39768); a.puts('" . a:message . "'); a.close\"")
endfunction


function! s:command_jump_to_breakpoint(cmd)
  let matched_cmd = matchlist(a:cmd, 'file="\(.*\)"\s*line="\(.*\)"')
  let file = matched_cmd[1]
  let line = matched_cmd[2]
  call s:open_file(file, line)
endfunction

function! s:command_set_breakpoint(cmd)
  let
endfunction


function! s:open_file(file, line)
  " If no buffer with this file has been loaded, create new one
  echo a:file
  echo a:line
  if !bufexists(bufname(a:file))
     exe ":e! " . l:fileName
  endif

  let l:winNr = bufwinnr(bufnr(a:file))
  if l:winNr != -1
     exe l:winNr . "wincmd w"
  endif

  " open buffer of a:file
  if bufname(a:file) != bufname("%")
     exe ":buffer " . bufnr(a:file)
  endif

  " jump to line
  exe ":" . a:line
  normal z.
  if foldlevel(a:line) != 0
     normal zo
  endif

  return bufname(a:file)

endfunction
