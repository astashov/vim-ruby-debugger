" *** Common (global) functions

" Split string of tags to List. E.g., 
" <variables><variable name="a" value="b" /><variable name="c" value="d" /></variables>
" will be splitted to 
" [ '<variable name="a" value="b" />', '<variable name="c" value="d" />' ]
function! s:get_tags(cmd)
  let tags = []
  let cmd = a:cmd
  " Remove wrap tags
  let inner_tags_match = s:get_inner_tags(cmd)
  if !empty(inner_tags_match)
    " Then find every tag and remove it from source string
    let pattern = '<.\{-}\/>' 
    let inner_tags = inner_tags_match[1]
    let tagmatch = matchlist(inner_tags, pattern)
    while empty(tagmatch) == 0
      call add(tags, tagmatch[0])
      " These symbols are interpretated as special, we need to escape them
      let tagmatch[0] = escape(tagmatch[0], '[]~*\')
      " Remove it from source string
      let inner_tags = substitute(inner_tags, tagmatch[0], '', '')
      " Find next tag
      let tagmatch = matchlist(inner_tags, pattern)
    endwhile
  endif
  return tags
endfunction


" Converts command with relative path to absolute path. If given command
" contains relative path, it will try to use 'which' on it first, and if
" 'which' returns nothing, it will add current dir path to given command
function! s:get_escaped_absolute_path(command)
  " Remove leading and trailing quotes
  let given_path = a:command
  let given_path = substitute(given_path, '"', '\"', "g")
  let given_path = substitute(given_path, "^'", '', "g")
  let given_path = substitute(given_path, "'$", '', "g")
  if given_path[0] == '/'
    let absolute_path = given_path
  else
    let parts = split(given_path)
    let relative_command = remove(parts, 0)
    let arguments = join(parts)
    let absolute_command = ""
    " I don't know Windows analogue for 'which', if you know - feel free to add it here
    if !(has("win32") || has("win64"))
      let absolute_command = s:strip(system('which ' . relative_command))
    endif
    if absolute_command[0] != '/'
      let absolute_command = getcwd() . '/' . relative_command
    endif
    let absolute_path = "\"'" . absolute_command . "' " . arguments . '"'
  endif
  return absolute_path
endfunction


" Return a string without leading and trailing spaces and linebreaks.
function! s:strip(input_string)
  return substitute(substitute(a:input_string, "\n", '', 'g'), '(\s*\(.\{-}\)\s*', '\1', 'g')
endfunction


" Shortcut for g:RubyDebugger.logger.debug
function! s:log(string)
  call g:RubyDebugger.logger.put(a:string)
endfunction


" Return match of inner tags without wrap tags. E.g.:
" <variables><variable name="a" value="b" /></variables> mathes only <variable /> 
function! s:get_inner_tags(cmd)
  return matchlist(a:cmd, '^<.\{-}>\(.\{-}\)<\/.\{-}>$')
endfunction 


" Return Dict of attributes.
" E.g., from <variable name="a" value="b" /> it returns
" {'name' : 'a', 'value' : 'b'}
function! s:get_tag_attributes(cmd)
  let attributes = {}
  let cmd = a:cmd
  " Find type of used quotes (" or ')
  let quote_match = matchlist(cmd, "\\w\\+=\\(.\\)")
  let quote = empty(quote_match) ? "\"" : escape(quote_match[1], "'\"")
  let pattern = "\\(\\w\\+\\)=" . quote . "\\(.\\{-}\\)" . quote
  " Find every attribute and remove it from source string
  let attrmatch = matchlist(cmd, pattern) 
  while !empty(attrmatch)
    " Values of attributes can be escaped by HTML entities, unescape them
    let attributes[attrmatch[1]] = s:unescape_html(attrmatch[2])
    " These symbols are interpretated as special, we need to escape them
    let attrmatch[0] = escape(attrmatch[0], '[]~*\')
    " Remove it from source string
    let cmd = substitute(cmd, attrmatch[0], '', '')
    " Find next attribute
    let attrmatch = matchlist(cmd, pattern) 
  endwhile
  return attributes
endfunction


" Unescape HTML entities
function! s:unescape_html(html)
  let result = substitute(a:html, "&amp;", "\\&", "g")
  let result = substitute(result, "&quot;", "\"", "g")
  let result = substitute(result, "&lt;", "<", "g")
  let result = substitute(result, "&gt;", ">", "g")
  return result
endfunction


function! s:quotify(exp)
  let quoted = a:exp
  let quoted = substitute(quoted, "\"", "\\\\\"", 'g')
  return quoted
endfunction


" Get filename of current buffer
function! s:get_filename()
  return expand("%:p")
endfunction


" Send message to debugger. This function should never be used explicitly,
" only through g:RubyDebugger.send_command function
function! s:send_message_to_debugger(message)
  call s:log("Sending a message to ruby_debugger.rb: '" . a:message . "'")
  if g:ruby_debugger_fast_sender
    call s:log("Trying to use experimental 'fast_sender'")
    let cmd = s:runtime_dir . "/bin/socket " . s:hostname . " " . s:debugger_port . " \"" . a:message . "\""
    call s:log("Executing command: " . cmd)
    call system(cmd)
  else
    if g:ruby_debugger_builtin_sender
      call s:log("Using Vim built-in Ruby to send message")
ruby << RUBY
  require 'socket'
  attempts = 0
  a = nil
  host = VIM::evaluate("s:hostname")
  port = VIM::evaluate("s:debugger_port")
  message = VIM::evaluate("a:message").gsub("\\\"", '"')
  begin
    a = TCPSocket.open(host, port)
    a.puts(message)
    a.close
  rescue Errno::ECONNREFUSED
   attempts += 1
   if attempts < 400
     sleep 0.05
     retry
   else
     puts("#{host}:#{port} can not be opened")
     exit
   end
  ensure
    a.close if a && !a.closed?
  end
RUBY
    else
      let script =  "ruby -e \"require 'socket'; "
      let script .= "attempts = 0; "
      let script .= "a = nil; "
      let script .= "begin; "
      let script .=   "a = TCPSocket.open('" . s:hostname . "', " . s:debugger_port . "); "
      let script .=   "a.puts(%q[" . substitute(substitute(a:message, '[', '\[', 'g'), ']', '\]', 'g') . "]);"
      let script .=   "a.close; "
      let script .= "rescue Errno::ECONNREFUSED; "
      let script .=   "attempts += 1; "
      let script .=   "if attempts < 400; "
      let script .=     "sleep 0.05; "
      let script .=     "retry; "
      let script .=   "else; "
      let script .=     "puts('" . s:hostname . ":" . s:debugger_port . " can not be opened'); "
      let script .=     "exit; "
      let script .=   "end; "
      let script .= "ensure; "
      let script .=   "a.close if a && !a.closed?; "
      let script .= "end; \""
      call s:log("Using system-wide Ruby to send message, the command is: " . script)
      let output = system(script)
      call s:log("Command has returned following output: " . output)
      if output =~ 'can not be opened'
        call s:log("Can't send a message to rdebug - port is not opened") 
      endif
    endif
  endif
endfunction


function! s:unplace_sign_of_current_line()
  if has("signs")
    exe ":sign unplace " . s:current_line_sign_id
  endif
endfunction


" Remove all variables of current line, remove current line sign. Usually it
" is needed before next/step/cont commands
function! s:clear_current_state()
  call s:unplace_sign_of_current_line()
  let g:RubyDebugger.variables = {}
  let g:RubyDebugger.frames = []
  " Clear variables and frames window (just show our empty variables Dict)
  if s:variables_window.is_open()
    call s:variables_window.open()
  endif
  if s:frames_window.is_open()
    call s:frames_window.open()
  endif
endfunction


" Open given file and jump to given line
" (stolen from NERDTree)
function! s:jump_to_file(file, line)
  "if the file is already open in this tab then just stick the cursor in it
  let window_number = bufwinnr('^' . a:file . '$')
  if window_number != -1
    exe window_number . "wincmd w"
  else
    " Check if last accessed window is usable to use it
    " Usable window - not quickfix, explorer, modified, etc 
    if !s:is_window_usable(winnr("#"))
      exe s:first_normal_window() . "wincmd w"
    else
      " If it is usable, jump to it
      exe 'wincmd p'
    endif
    exe "edit " . a:file
  endif
  exe "normal " . a:line . "G"
endfunction


" Return 1 if window is usable (not quickfix, explorer, modified, only one 
" window, ...) 
function! s:is_window_usable(winnumber)
  "If there is only one window (winnr("$") - windows count)
  if winnr("$") ==# 1
    return 0
  endif

  " Current window number
  let oldwinnr = winnr()

  " Switch to given window and check it
  exe a:winnumber . "wincmd p"
  let specialWindow = getbufvar("%", '&buftype') != '' || getwinvar('%', '&previewwindow')
  let modified = &modified

  exe oldwinnr . "wincmd p"

  "if it is a special window, e.g. quickfix or another explorer plugin    
  if specialWindow
    return 0
  endif

  if &hidden
    return 1
  endif

  " If this window is modified, but there is another opened window with
  " current file, return 1. Otherwise - 0
  return !modified || s:buf_in_windows(winbufnr(a:winnumber)) >= 2
endfunction


" Determine the number of windows open to this buffer number.
function! s:buf_in_windows(buffer_number)
  let count = 0
  let window_number = 1
  while 1
    let buffer_number = winbufnr(window_number)
    if buffer_number < 0
      break
    endif
    if buffer_number ==# a:buffer_number
      let count = count + 1
    endif
    let window_number = window_number + 1
  endwhile

  return count
endfunction 


" Find first 'normal' window (not quickfix, explorer, etc)
function! s:first_normal_window()
  let i = 1
  while i <= winnr("$")
    let bnum = winbufnr(i)
    if bnum != -1 && getbufvar(bnum, '&buftype') ==# '' && !getwinvar(i, '&previewwindow')
      return i
    endif
    let i += 1
  endwhile
  return -1
endfunction
