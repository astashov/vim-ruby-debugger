" *** Public interface (start)

let RubyDebugger = { 'commands': {}, 'variables': {}, 'settings': {}, 'breakpoints': [] }


" Run debugger server. It takes one optional argument with path to debugged
" ruby script ('script/server webrick' by default)
function! RubyDebugger.start(...) dict
  let g:RubyDebugger.server = s:Server.new(s:hostname, s:rdebug_port, s:debugger_port, s:runtime_dir, s:tmp_file, s:server_output_file)
  let script = a:0 && !empty(a:1) ? a:1 : 'script/server webrick'
  echo "Loading debugger..."
  call g:RubyDebugger.server.start(script)

  " Send only first breakpoint to the debugger. All other breakpoints will be
  " sent by 'set_breakpoint' command
  let breakpoint = get(g:RubyDebugger.breakpoints, 0)
  if type(breakpoint) == type({})
    call breakpoint.send_to_debugger()
  else
    " if there are no breakpoints, just run the script
    call g:RubyDebugger.send_command('start')
  endif
  echo "Debugger started"
endfunction


" Stop running server.
function! RubyDebugger.stop() dict
  if has_key(g:RubyDebugger, 'server')
    call g:RubyDebugger.server.stop()
  endif
endfunction


" This function receives commands from the debugger. When ruby_debugger.rb
" gets output from rdebug-ide, it writes it to the special file and 'kick'
" the plugin by remotely calling RubyDebugger.receive_command(), e.g.:
" vim --servername VIM --remote-send 'call RubyDebugger.receive_command()'
" That's why +clientserver is required
" This function analyzes the special file and gives handling to right command
function! RubyDebugger.receive_command() dict
  let cmd = join(readfile(s:tmp_file), "")
  call g:RubyDebugger.logger.put("Received command: " . cmd)
  " Clear command line
  if !empty(cmd)
    if match(cmd, '<breakpoint ') != -1
      call g:RubyDebugger.commands.jump_to_breakpoint(cmd)
    elseif match(cmd, '<suspended ') != -1
      call g:RubyDebugger.commands.jump_to_breakpoint(cmd)
    elseif match(cmd, '<breakpointAdded ') != -1
      call g:RubyDebugger.commands.set_breakpoint(cmd)
    elseif match(cmd, '<variables>') != -1
      call g:RubyDebugger.commands.set_variables(cmd)
    elseif match(cmd, '<error>') != -1
      call g:RubyDebugger.commands.error(cmd)
    elseif match(cmd, '<message>') != -1
      call g:RubyDebugger.commands.message(cmd)
    elseif match(cmd, '<eval ') != -1
      call g:RubyDebugger.commands.eval(cmd)
    endif
  endif
endfunction


" We set function this way, because we want have possibility to mock it by
" other function in tests
let RubyDebugger.send_command = function("<SID>send_message_to_debugger")


" Open variables window
function! RubyDebugger.open_variables() dict
  call s:variables_window.toggle()
  call g:RubyDebugger.logger.put("Opened variables window")
endfunction


" Open breakpoints window
function! RubyDebugger.open_breakpoints() dict
  call s:breakpoints_window.toggle()
  call g:RubyDebugger.logger.put("Opened breakpoints window")
endfunction


" Set/remove breakpoint at current position
function! RubyDebugger.toggle_breakpoint() dict
  let line = line(".")
  let file = s:get_filename()
  let existed_breakpoints = filter(copy(g:RubyDebugger.breakpoints), 'v:val.line == ' . line . ' && v:val.file == "' . escape(file, '\') . '"')
  " If breakpoint with current file/line doesn't exist, create it. Otherwise -
  " remove it
  if empty(existed_breakpoints)
    let breakpoint = s:Breakpoint.new(file, line)
    call add(g:RubyDebugger.breakpoints, breakpoint)
    call breakpoint.send_to_debugger() 
  else
    let breakpoint = existed_breakpoints[0]
    call filter(g:RubyDebugger.breakpoints, 'v:val.id != ' . breakpoint.id)
    call breakpoint.delete()
  endif
  " Update info in Breakpoints window
  if s:breakpoints_window.is_open()
    call s:breakpoints_window.open()
    exe "wincmd p"
  endif
endfunction


" Remove all breakpoints
function! RubyDebugger.remove_breakpoints() dict
  for breakpoint in g:RubyDebugger.breakpoints
    call breakpoint.delete()
  endfor
  let g:RubyDebugger.breakpoints = []
endfunction


" Next
function! RubyDebugger.next() dict
  call g:RubyDebugger.send_command("next")
  call s:clear_current_state()
  call g:RubyDebugger.logger.put("Step over")
endfunction


" Step
function! RubyDebugger.step() dict
  call g:RubyDebugger.send_command("step")
  call s:clear_current_state()
  call g:RubyDebugger.logger.put("Step into")
endfunction


" Continue
function! RubyDebugger.continue() dict
  call g:RubyDebugger.send_command("cont")
  call s:clear_current_state()
  call g:RubyDebugger.logger.put("Continue")
endfunction


" Exit
function! RubyDebugger.exit() dict
  call g:RubyDebugger.send_command("exit")
  call s:clear_current_state()
endfunction


" Debug current opened test
function! RubyDebugger.run_test() dict
  let file = s:get_filename()
  if file =~ '_spec\.rb$'
    call g:RubyDebugger.start(g:ruby_debugger_spec_path . ' ' . file)
  elseif file =~ '\.feature$'
    call g:RubyDebugger.start(g:ruby_debugger_cucumber_path . ' ' . file)
  elseif file =~ '_test\.rb$'
    call g:RubyDebugger.start(file)
  endif
endfunction


" *** Public interface (end)



