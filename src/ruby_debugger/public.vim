" *** Public interface (start)

let RubyDebugger = { 'commands': {}, 'variables': {}, 'settings': {}, 'breakpoints': [], 'frames': [], 'exceptions': [] }
let g:RubyDebugger.queue = s:Queue.new()


" Run debugger server. It takes one optional argument with path to debugged
" ruby script ('script/server webrick' by default)
function! RubyDebugger.start(...) dict
  call s:log("Executing :Rdebugger...")
  let g:RubyDebugger.server = s:Server.new(s:hostname, s:rdebug_port, s:debugger_port, s:runtime_dir, s:tmp_file, s:server_output_file)
  let script_string = a:0 && !empty(a:1) ? a:1 : g:ruby_debugger_default_script
  let params = a:0 && a:0 > 1 && !empty(a:2) ? a:2 : []
  echo "Loading debugger..."
  call g:RubyDebugger.server.start(s:get_escaped_absolute_path(script_string), params)

  let g:RubyDebugger.exceptions = []
  for breakpoint in g:RubyDebugger.breakpoints
    call g:RubyDebugger.queue.add(breakpoint.command())
  endfor
  call g:RubyDebugger.queue.add('start')
  echo "Debugger started"
  call g:RubyDebugger.queue.execute()
endfunction


" Stop running server.
function! RubyDebugger.stop() dict
  if has_key(g:RubyDebugger, 'server')
    call g:RubyDebugger.server.stop()
  endif
endfunction

function! RubyDebugger.is_running()
  if has_key(g:RubyDebugger, 'server')
    return g:RubyDebugger.server.is_running()
  endif
  return 0
endfunction

" This function receives commands from the debugger. When ruby_debugger.rb
" gets output from rdebug-ide, it writes it to the special file and 'kick'
" the plugin by remotely calling RubyDebugger.receive_command(), e.g.:
" vim --servername VIM --remote-send 'call RubyDebugger.receive_command()'
" That's why +clientserver is required
" This function analyzes the special file and gives handling to right command
function! RubyDebugger.receive_command() dict
  let file_contents = join(readfile(s:tmp_file), "")
  call s:log("Received command: " . file_contents)
  let commands = split(file_contents, s:separator)
  for cmd in commands
    if !empty(cmd)
      if match(cmd, '<breakpoint ') != -1
        call g:RubyDebugger.commands.jump_to_breakpoint(cmd)
      elseif match(cmd, '<suspended ') != -1
        call g:RubyDebugger.commands.jump_to_breakpoint(cmd)
      elseif match(cmd, '<exception ') != -1
        call g:RubyDebugger.commands.handle_exception(cmd)
      elseif match(cmd, '<breakpointAdded ') != -1
        call g:RubyDebugger.commands.set_breakpoint(cmd)
      elseif match(cmd, '<catchpointSet ') != -1
        call g:RubyDebugger.commands.set_exception(cmd)
      elseif match(cmd, '<variables>') != -1
        call g:RubyDebugger.commands.set_variables(cmd)
      elseif match(cmd, '<error>') != -1
        call g:RubyDebugger.commands.error(cmd)
      elseif match(cmd, '<message>') != -1
        call g:RubyDebugger.commands.message(cmd)
      elseif match(cmd, '<eval ') != -1
        call g:RubyDebugger.commands.eval(cmd)
      elseif match(cmd, '<processingException ') != -1
        call g:RubyDebugger.commands.processing_exception(cmd)
      elseif match(cmd, '<frames>') != -1
        call g:RubyDebugger.commands.trace(cmd)
      endif
    endif
  endfor
  call g:RubyDebugger.queue.after_hook()
  call g:RubyDebugger.queue.execute()
endfunction


function! RubyDebugger.send_command_wrapper(command)
  call g:RubyDebugger.send_command(a:command)
endfunction

" We set function this way, because we want have possibility to mock it by
" other function in tests
let RubyDebugger.send_command = function("<SID>send_message_to_debugger")


" Open variables window
function! RubyDebugger.open_variables() dict
  call s:variables_window.toggle()
  call s:log("Opened variables window")
  call g:RubyDebugger.queue.execute()
endfunction


" Open breakpoints window
function! RubyDebugger.open_breakpoints() dict
  call s:breakpoints_window.toggle()
  call s:log("Opened breakpoints window")
  call g:RubyDebugger.queue.execute()
endfunction


" Open frames window
function! RubyDebugger.open_frames() dict
  call s:frames_window.toggle()
  call s:log("Opened frames window")
  call g:RubyDebugger.queue.execute()
endfunction


" Set/remove breakpoint at current position. If argument
" is given, it will set conditional breakpoint (argument is condition)
function! RubyDebugger.toggle_breakpoint(...) dict
  let line = line(".")
  let file = s:get_filename()
  call s:log("Trying to toggle a breakpoint in the file " . file . ":" . line)
  let existed_breakpoints = filter(copy(g:RubyDebugger.breakpoints), 'v:val.line == ' . line . ' && v:val.file == "' . escape(file, '\') . '"')
  " If breakpoint with current file/line doesn't exist, create it. Otherwise -
  " remove it
  if empty(existed_breakpoints)
    call s:log("There is no already set breakpoint, so create new one")
    let breakpoint = s:Breakpoint.new(file, line)
    call add(g:RubyDebugger.breakpoints, breakpoint)
    call s:log("Added Breakpoint object to RubyDebugger.breakpoints array")
    call breakpoint.send_to_debugger() 
  else
    call s:log("There is already set breakpoint presented, so delete it")
    let breakpoint = existed_breakpoints[0]
    call filter(g:RubyDebugger.breakpoints, 'v:val.id != ' . breakpoint.id)
    call s:log("Removed Breakpoint object from RubyDebugger.breakpoints array")
    call breakpoint.delete()
  endif
  " Update info in Breakpoints window
  if s:breakpoints_window.is_open()
    call s:breakpoints_window.open()
    exe "wincmd p"
  endif
  call g:RubyDebugger.queue.execute()
endfunction


" Remove all breakpoints
function! RubyDebugger.remove_breakpoints() dict
  for breakpoint in g:RubyDebugger.breakpoints
    call breakpoint.delete()
  endfor
  let g:RubyDebugger.breakpoints = []
  call g:RubyDebugger.queue.execute()
endfunction


" Eval the passed in expression
function! RubyDebugger.eval(exp) dict
  let quoted = s:quotify(a:exp)
  call g:RubyDebugger.queue.add("eval " . quoted)
  call g:RubyDebugger.queue.execute()
endfunction


" Sets conditional breakpoint where cursor is placed
function! RubyDebugger.conditional_breakpoint(exp) dict
  let line = line(".")
  let file = s:get_filename()
  let existed_breakpoints = filter(copy(g:RubyDebugger.breakpoints), 'v:val.line == ' . line . ' && v:val.file == "' . escape(file, '\') . '"')
  " If breakpoint with current file/line doesn't exist, create it. Otherwise -
  " remove it
  if empty(existed_breakpoints)
    echo "You can set condition only to already set breakpoints. Move cursor to set breakpoint and add condition"
  else
    let breakpoint = existed_breakpoints[0]
    let quoted = s:quotify(a:exp)
    call breakpoint.add_condition(quoted)
    " Update info in Breakpoints window
    if s:breakpoints_window.is_open()
      call s:breakpoints_window.open()
      exe "wincmd p"
    endif
    call g:RubyDebugger.queue.execute()
  endif
endfunction


" Catch all exceptions with given name
function! RubyDebugger.catch_exception(exp) dict
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running()
    let quoted = s:quotify(a:exp)
    let exception = s:Exception.new(quoted)
    call add(g:RubyDebugger.exceptions, exception)
    if s:breakpoints_window.is_open()
      call s:breakpoints_window.open()
      exe "wincmd p"
    endif
    call g:RubyDebugger.queue.execute()
  else
    echo "Sorry, but you can set Exceptional Breakpoints only with running debugger"
  endif
endfunction


" Next
function! RubyDebugger.next() dict
  call g:RubyDebugger.queue.add("next")
  call s:clear_current_state()
  call s:log("Step over")
  call g:RubyDebugger.queue.execute()
endfunction


" Step
function! RubyDebugger.step() dict
  call g:RubyDebugger.queue.add("step")
  call s:clear_current_state()
  call s:log("Step into")
  call g:RubyDebugger.queue.execute()
endfunction


" Finish
function! RubyDebugger.finish() dict
  call g:RubyDebugger.queue.add("finish")
  call s:clear_current_state()
  call s:log("Step out")
  call g:RubyDebugger.queue.execute()
endfunction


" Continue
function! RubyDebugger.continue() dict
  call g:RubyDebugger.queue.add("cont")
  call s:clear_current_state()
  call s:log("Continue")
  call g:RubyDebugger.queue.execute()
endfunction


" Exit
function! RubyDebugger.exit() dict
  call g:RubyDebugger.queue.add("exit")
  call s:clear_current_state()
  call g:RubyDebugger.queue.execute()
endfunction


" Show output log of Ruby script
function! RubyDebugger.show_log() dict
  exe "view " . s:server_output_file
  setlocal autoread
  " Per gorkunov's request 
  setlocal wrap
  setlocal nonumber
  if exists(":AnsiEsc")
    exec ":AnsiEsc"
  endif
endfunction


" Debug current opened test
function! RubyDebugger.run_test() dict
  let file = s:get_filename()
  if file =~ '_spec\.rb$'
    call g:RubyDebugger.start(g:ruby_debugger_spec_path . ' ' . file)
  elseif file =~ '\.feature$'
    call g:RubyDebugger.start(g:ruby_debugger_cucumber_path . ' ' . file)
  elseif file =~ '_test\.rb$'
    call g:RubyDebugger.start(file, ['-Itest'])
  endif
endfunction


" *** Public interface (end)



