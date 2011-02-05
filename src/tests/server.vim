let s:Tests.server = {}

function! s:Tests.server.before_all()
  let g:RubyDebugger.breakpoints = []
  let g:RubyDebugger.frames = []
  let g:RubyDebugger.variables = {} 
endfunction

function! s:Tests.server.before()
  call g:RubyDebugger.queue.empty() 
  call s:Server._stop_server(s:rdebug_port)
  call s:Server._stop_server(s:debugger_port)
endfunction

function! s:Tests.server.test_should_run_server(test)
  exe "Rdebugger" 
  call g:TU.ok(type(g:RubyDebugger.server) == type({}), "Server should be initialized", a:test)
  call g:TU.ok(g:RubyDebugger.server.is_running(), "Server should be run", a:test)
  call g:TU.ok(g:RubyDebugger.server.rdebug_pid != "", "Process rdebug-ide should be run", a:test)
  call g:TU.ok(g:RubyDebugger.server.debugger_pid != "", "Process debugger.rb should be run", a:test)
endfunction


function! s:Tests.server.test_should_stop_server(test)
  exe "Rdebugger"
  call g:RubyDebugger.server.stop()
  call g:TU.ok(!g:RubyDebugger.server.is_running(), "Server should not be run", a:test)
  call g:TU.equal("", s:Server._get_pid(s:rdebug_port, 0), "Process rdebug-ide should not exist", a:test)
  call g:TU.equal("", s:Server._get_pid(s:debugger_port, 0), "Process debugger.rb should not exist", a:test)
  call g:TU.equal("", g:RubyDebugger.server.rdebug_pid, "Pid of rdebug-ide should be nullified", a:test)
  call g:TU.equal("", g:RubyDebugger.server.debugger_pid, "Pid of debugger.rb should be nullified", a:test)
endfunction


function! s:Tests.server.test_should_kill_old_server_before_starting_new(test)
  exe "Rdebugger"
  let old_rdebug_pid = g:RubyDebugger.server.rdebug_pid
  let old_debugger_pid = g:RubyDebugger.server.debugger_pid
  exe "Rdebugger"
  call g:TU.ok(g:RubyDebugger.server.is_running(), "Server should be run", a:test)
  call g:TU.ok(g:RubyDebugger.server.rdebug_pid != "", "Process rdebug-ide should be run", a:test)
  call g:TU.ok(g:RubyDebugger.server.debugger_pid != "", "Process debugger.rb should be run", a:test)
  call g:TU.ok(g:RubyDebugger.server.rdebug_pid != old_rdebug_pid, "Rdebug-ide should have new pid", a:test)
  call g:TU.ok(g:RubyDebugger.server.debugger_pid != old_debugger_pid, "Debugger.rb should have new pid", a:test)
endfunction

 

