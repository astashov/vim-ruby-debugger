" Vim plugin for debugging Rails applications
" Maintainer: Anton Astashov (anton at astashov dot net, http://astashov.net)

map <Leader>b  :call RubyDebugger.set_breakpoint()<CR>
map <Leader>r  :call RubyDebugger.receive_command()<CR>
map <Leader>v  :call RubyDebugger.variables.toggle()<CR>
command! Rdebugger :call RubyDebugger.start() 

let RubyDebugger = { 'commands': {}, 'variables': {} }

let s:rdebug_port = 39767
let s:debugger_port = 39768

" Init breakpoing signs
hi breakpoint  term=NONE    cterm=NONE    gui=NONE
sign define breakpoint  linehl=breakpoint  text=>>


" *** Public interface ***


function! RubyDebugger.start() dict
  let rdebug = 'rdebug-ide -p ' . s:rdebug_port . ' -- script/server &'
  let debugger = 'ruby ' . expand("~/.vim/bin/debugger.rb") . ' ' . s:rdebug_port . ' ' . s:debugger_port . ' ' . v:progname . ' ' . v:servername . ' &'
  call system(rdebug)
  exe 'sleep 1'
  call system(debugger)
endfunction


function! RubyDebugger.receive_command(cmd) dict
  let cmd = a:cmd
  echo cmd
  if empty(cmd) == 0
    if match(cmd, '<breakpoint ') != -1
      call g:RubyDebugger.commands.jump_to_breakpoint(cmd)
    elseif match(cmd, '<breakpointAdded ') != -1
      call g:RubyDebugger.commands.set_breakpoint(cmd)
    endif
  endif
endfunction


function! RubyDebugger.set_breakpoint() dict
  let line = line(".")
  let file = s:get_filename()
  let message = 'break ' . file . ':' . line
  call s:send_message_to_debugger(message)
endfunction


" *** End of public interface


" *** RubyDebugger Commands *** 


" <breakpoint file="test.rb" line="1" threadId="1" />
function! RubyDebugger.commands.jump_to_breakpoint(cmd) dict
  let attrs = s:get_tag_attributes(a:cmd) 
  call s:jump_to_file(attrs.file, attrs.line)
endfunction


" <breakpointAdded no="1" location="test.rb:2" />
function! RubyDebugger.commands.set_breakpoint(cmd)
  let attrs = s:get_tag_attributes(a:cmd)
  let file_match = matchlist(attrs.location, '\(.*\):\(.*\)')
  exe ":sign place " . attrs.no . " line=" . file_match[2] . " name=breakpoint file=" . file_match[1]
endfunction


" *** End of debugger Commands ***

" *** Variables window ***

function! RubyDebugger.variables.toggle() dict
  if !s:is_variables_window_open()
    call g:RubyDebugger.variables.create_window()
  else
    call g:RubyDebugger.variables.close_window()
  endif
endfunction


function! RubyDebugger.variables.create_window() dict
    " create the variables tree window
    let splitLocation = "botright "
    let splitSize = 10
    exec splitLocation . ' ' . splitSize . ' new'

    let g:variables_buffer_name = 'Variables_Window' 
    silent! exec "edit " . g:variables_buffer_name
    let g:variables_buffer_number = bufnr("%")

    " set buffer options
    setlocal winfixwidth
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    iabc <buffer>
    setlocal cursorline
    setfiletype variablestree

    call RubyDebugger.variables.update()
endfunction


function! RubyDebugger.variables.close_window() dict
  if !s:is_variables_window_open()
    throw "No Variables Tree is open"
  endif

  exe 'buffer ' . g:variables_buffer_number
  close
  unlet g:variables_buffer_name
  unlet g:variables_buffer_number
endfunction


function! RubyDebugger.variables.update() dict

endfunction

function! s:is_variables_window_open()
    return exists("g:variables_buffer_name") && bufloaded(g:variables_buffer_name)
endfunction


" *** End of variables window ***


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
