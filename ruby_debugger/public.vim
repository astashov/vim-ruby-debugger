" *** Public interface ***

let RubyDebugger = { 'commands': {}, 'variables': {}, 'settings': {} }

function! RubyDebugger.start() dict
  let rdebug = 'rdebug-ide -p ' . s:rdebug_port . ' -- script/server &'
  let debugger = 'ruby ' . expand(s:runtime_dir . "/bin/ruby_debugger.rb") . ' ' . s:rdebug_port . ' ' . s:debugger_port . ' ' . v:progname . ' ' . v:servername . ' "' . s:tmp_file . '" &'
  call system(rdebug)
  exe 'sleep 2'
  call system(debugger)
  call g:RubyDebugger.logger.put("Start debugger")
endfunction


function! RubyDebugger.receive_command() dict
  let cmd = join(readfile(s:tmp_file), "")
  call g:RubyDebugger.logger.put("Received command: " . cmd)
  " Clear command line
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


function! RubyDebugger.open_variables() dict
"  if g:RubyDebugger.variables == {}
"    echo "You are not in the running program"
"  else
    call s:variables_window.toggle()
  call g:RubyDebugger.logger.put("Opened variables window")
"  endif
endfunction


function! RubyDebugger.set_breakpoint() dict
  let line = line(".")
  let file = s:get_filename()
  let message = 'break ' . file . ':' . line
  call s:send_message_to_debugger(message)
  call g:RubyDebugger.logger.put("Set breakpoint to: " . file . ":" . line)
endfunction


" *** End of public interface



