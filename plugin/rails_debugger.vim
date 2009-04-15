" Vim plugin for debugging Rails applications
" Maintainer: Anton Astashov (anton at astashov dot net, http://astashov.net)

map <Leader>b  :call Debugger.set_breakpoint()<CR>
map <Leader>r  :call Debugger.receive_command()<CR>
command! Rdebugger :call Debugger.start() 

let Debugger = { 'commands': {} }

let s:rdebug_port = 39767
let s:debugger_port = 39768
" let s:buffer_file = expand('~/.vim/tmp/buffer_debugger')


" Init breakpoing signs
hi breakpoint  term=NONE    cterm=NONE    gui=NONE
sign define breakpoint  linehl=breakpoint  text=>>


" Create directory for temporary (buffer) file
" call system('mkdir -p ~/.vim/tmp')
" call system('touch ~/.vim/tmp/' . s:buffer_file)

" Open file for input debugger commands
" exe 'sp ' . s:buffer_file 
" exe 'hide'

" When file for input debugger commands is changed (new command is arrived),
" it will process the command
" set updatetime=1000
" exe 'au! CursorHold * call Debugger.receive_command()'


" *** Public interface ***


function! Debugger.start() dict
  let rdebug = 'rdebug-ide -p ' . s:rdebug_port . ' -- script/server &'
  let debugger = 'ruby ' . expand("~/.vim/bin/debugger.rb") . ' ' . s:rdebug_port . ' ' . s:debugger_port . ' ' . v:progname . ' ' . v:servername . ' &'
  call system(rdebug)
  exe 'sleep 1'
  call system(debugger)
endfunction


function! Debugger.receive_command(cmd) dict
  let cmd = a:cmd
  echo cmd
  if empty(cmd) == 0
    if match(cmd, '<breakpoint ') != -1
      call g:Debugger.commands.jump_to_breakpoint(cmd)
    elseif match(cmd, '<breakpointAdded ') != -1
      call g:Debugger.commands.set_breakpoint(cmd)
    endif
  endif
endfunction


function! Debugger.set_breakpoint() dict
  let line = line(".")
  let file = s:get_filename()
  let message = 'break ' . file . ':' . line
  call s:send_message_to_debugger(message)
endfunction


" *** End of public interface


" *** Debugger Commands *** 


" <breakpoint file="test.rb" line="1" threadId="1" />
function! Debugger.commands.jump_to_breakpoint(cmd) dict
  let attrs = s:get_tag_attributes(a:cmd) 
  call s:jump_to_file(attrs.file, attrs.line)
endfunction


" <breakpointAdded no="1" location="test.rb:2" />
function! Debugger.commands.set_breakpoint(cmd)
  let attrs = s:get_tag_attributes(a:cmd)
  let file_match = matchlist(attrs.location, '\(.*\):\(.*\)')
  exe ":sign place " . attrs.no . " line=" . file_match[2] . " name=breakpoint file=" . file_match[1]
endfunction


" *** End of debugger Commands ***


function! s:get_tag_attributes(cmd)
  let attributes = {}
  let cmd = a:cmd
  let pattern = '\(\w\+\)="\(.\{-}\)"'
  let tagmatch = matchlist(cmd, pattern) 
  while empty(tagmatch) == 0
    let attributes[tagmatch[1]] = tagmatch[2]
    let cmd = substitute(cmd, tagmatch[0], '', '')
    let tagmatch = matchlist(cmd, pattern) 
  endwhile
  return attributes
endfunction


function! s:get_filename()
  return bufname("%")
endfunction


function! s:send_message_to_debugger(message)
  call system("ruby -e \"require 'socket'; a = TCPSocket.open('localhost', 39768); a.puts('" . a:message . "'); a.close\"")
endfunction


function! s:jump_to_file(file, line)
  " If no buffer with this file has been loaded, create new one
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
