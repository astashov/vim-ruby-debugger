" Vim plugin for debugging Rails applications
" Maintainer: Anton Astashov (anton at astashov dot net, http://astashov.net)

map <Leader>b  :call RubyDebugger.set_breakpoint()<CR>
map <Leader>r  :call RubyDebugger.receive_command()<CR>
map <Leader>v  :call RubyDebugger.variables.toggle()<CR>
command! Rdebugger :call RubyDebugger.start() 

" if exists("g:loaded_ruby_debugger")
"     finish
" endif
" if v:version < 700
"     echoerr "RubyDebugger: This plugin requires Vim >= 7."
"     finish
" endif
" let g:loaded_ruby_debugger = 1

let RubyDebugger = { 'commands': {}, 'variables': {}, 'settings': {} }

let s:rdebug_port = 39767
let s:debugger_port = 39768
let s:runtime_dir = split(&runtimepath, ',')[0]
let s:tmp_file = s:runtime_dir . '/tmp/ruby_debugger'

let s:variables_buf_name = "Variables_Window"
let s:next_buffer_number = 1

let RubyDebugger.settings.variables_win_position = 'botright'
let RubyDebugger.settings.variables_win_size = 10


" Init breakpoing signs
hi breakpoint  term=NONE    cterm=NONE    gui=NONE
sign define breakpoint  linehl=breakpoint  text=>>


" *** Public interface ***


function! RubyDebugger.start() dict
  let rdebug = 'rdebug-ide -p ' . s:rdebug_port . ' -- script/server &'
  let debugger = 'ruby ' . expand(s:runtime_dir . "/bin/ruby_debugger.rb") . ' ' . s:rdebug_port . ' ' . s:debugger_port . ' ' . v:progname . ' ' . v:servername . ' "' . s:tmp_file . '" &'
  call system(rdebug)
  exe 'sleep 1'
  call system(debugger)
endfunction


function! RubyDebugger.receive_command() dict
  let cmd = join(readfile(s:tmp_file), "\n")
  " Clear command line
  echo ""
  if !empty(cmd)
    if match(cmd, '<breakpoint ') != -1
      call g:RubyDebugger.commands.jump_to_breakpoint(cmd)
    elseif match(cmd, '<breakpointAdded ') != -1
      call g:RubyDebugger.commands.set_breakpoint(cmd)
    elseif match(cmd, '<variables>') != -1
      call g:RubyDebugger.commands.set_variables(cmd)
    endif
  endif
endfunction


function! RubyDebugger.nothing(asdf) dict
  echo "something"
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


" <variables>
"   <variable name="array" kind="local" value="Array (2 element(s))" type="Array" hasChildren="true" objectId="-0x2418a904"/>
" </variables>
function! RubyDebugger.commands.set_variables(cmd)
  let tags = s:get_tags(a:cmd)
  let list_of_variables = []
  for tag in tags
    let attrs = s:get_tag_attributes(tag)
    let variables = {}
    if has_key(attrs, 'name')
      let variables["name"] = attrs.name
    endif
    if has_key(attrs, 'value')
      let variables["value"] = attrs.value
    endif
    if has_key(attrs, 'type')
      let variables["type"] = attrs.type
    endif
    if has_key(attrs, 'hasChildren')
      let variables["has_children"] = attrs.hasChildren
    endif
    call add(list_of_variables, variables)
  endfor
  if !has_key(g:RubyDebugger.variables, 'list')
    g:RubyDebugger.variables.list = []
  endif
  call extend(g:RubyDebugger.variables.list, list_of_variables)
  call s:collect_variables()
endfunction

" *** End of debugger Commands ***

" *** Variables window ***

function! RubyDebugger.variables.toggle() dict
  if s:variables_exist_for_tab()
    if !s:is_variables_open()
      call self.create_window()
    else
      call self.close_window()
    endif
  else
    call self.init()
  end
endfunction


function! s:variables_exist_for_tab()
  return exists("t:variables_buf_name") 
endfunction


function! s:is_variables_open()
    return s:get_variables_win_num() != -1
endfunction


function! s:get_variables_win_num()
  if s:variables_exist_for_tab()
    return bufwinnr(t:variables_buf_name)
  else
    return -1
  endif
endfunction


function! s:next_buffer_name()
  let name = s:variables_buf_name . s:next_buffer_number
  let s:next_buffer_number += 1
  return name
endfunction


function! RubyDebugger.variables.init() dict
  if s:variables_exist_for_tab()
    if s:is_variables_open()
      call self.close_window()
    endif
    unlet t:variables_buf_name
  endif

  call self.create_window()

endfunction


function! RubyDebugger.variables.create_window() dict
    " create the variables tree window
    let splitLocation = g:RubyDebugger.settings.variables_win_position
    let splitSize = g:RubyDebugger.settings.variables_win_size
    silent exec splitLocation . ' ' . splitSize . ' new'

    if !exists('t:variables_buf_name')
      let t:variables_buf_name = s:next_buffer_name()
      silent! exec "edit " . t:variables_buf_name
    else
      silent! exec "buffer " . t:variables_buf_name
    endif

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

    call g:RubyDebugger.variables.update()
endfunction


function! RubyDebugger.variables.close_window() dict
  if !s:is_variables_open()
    throw "No Variables Tree is open"
  endif

  if winnr("$") != 1
    exe s:get_variables_win_num() . " wincmd w"
    close
    exe "wincmd p"
  else
    :q
  endif
endfunction


function! RubyDebugger.variables.update() dict


  let g:RubyDebugger.variables.need_to_get = [ 'local', 'self' ]
  let g:RubyDebugger.variables.list = []
  call s:collect_variables() 
endfunction


function! s:is_variables_window_open()
    return exists("g:variables_buffer_name") && bufloaded(g:variables_buffer_name)
endfunction

function! s:collect_variables()
  if !empty(g:RubyDebugger.variables.need_to_get)
    let type = remove(g:RubyDebugger.variables.need_to_get, 0)
    if type == 'local'
      call s:send_message_to_debugger('var local')
    elseif type == 'self'
      call s:send_message_to_debugger('var instance self')
    end
  else
    call s:display_variables()
  endif
endfunction


function! s:display_variables()
  let curLine = line(".")
  let curCol = col(".")
  let topLine = line("w0")
  " delete all lines in the buffer (being careful not to clobber a register)
  silent 1,$delete _
  for var in g:RubyDebugger.variables.list
    call setline(curLine, get(var, "name", "undefined") . "\t" . get(var, "type", "undefined") . "\t" . get(var, "value", "undefined"))
    let curLine = curLine + 1
  endfor
endfunction

" *** End of variables window ***

function! s:get_tags(cmd)
  let tags = []
  let cmd = a:cmd
  let inner_tags_match = matchlist(cmd, '^<.\{-}>\(.\{-}\)<\/.\{-}>$')
  if empty(inner_tags_match) == 0
    let pattern = '<.\{-}\/>' 
    let inner_tags = inner_tags_match[1]
    let tagmatch = matchlist(inner_tags, pattern)
    while empty(tagmatch) == 0
      call add(tags, tagmatch[0])
      let inner_tags = substitute(inner_tags, tagmatch[0], '', '')
      let tagmatch = matchlist(inner_tags, pattern)
    endwhile
  endif
  return tags
endfunction

function! s:get_tag_attributes(cmd)
  let attributes = {}
  let cmd = a:cmd
  let pattern = '\(\w\+\)="\(.\{-}\)"'
  let attrmatch = matchlist(cmd, pattern) 
  while empty(attrmatch) == 0
    let attributes[attrmatch[1]] = attrmatch[2]
    let cmd = substitute(cmd, attrmatch[0], '', '')
    let attrmatch = matchlist(cmd, pattern) 
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
