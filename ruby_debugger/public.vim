" *** Public interface ***


function! RubyDebugger.start() dict
  let rdebug = 'rdebug-ide -p ' . s:rdebug_port . ' -- script/server &'
  let debugger = 'ruby ' . expand(s:runtime_dir . "/bin/ruby_debugger.rb") . ' ' . s:rdebug_port . ' ' . s:debugger_port . ' ' . v:progname . ' ' . v:servername . ' "' . s:tmp_file . '" &'
  call system(rdebug)
  exe 'sleep 2'
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



