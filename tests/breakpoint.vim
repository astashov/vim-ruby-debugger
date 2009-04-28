let s:Tests.breakpoint = {}

function! s:Tests.breakpoint.before_all()
  let g:RubyDebugger.breakpoints = []
  let g:RubyDebugger.variables = {} 
  exe "Rdebugger"
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.breakpoint.after_all()
  call s:Server._stop_server('localhost', s:rdebug_port)
  call s:Server._stop_server('localhost', s:debugger_port)
  call s:Mock.unmock_debugger()
endfunction


function! s:Tests.breakpoint.test_should_set_breakpoint(test)
  let filename = s:runtime_dir . "/tmp/ruby_debugger_test_file"
  exe "new " . filename
  call g:RubyDebugger.set_breakpoint()
  let breakpoint = get(g:RubyDebugger.breakpoints, 0)
  call g:TU.equal(1, breakpoint.id, "Id of first breakpoint should == 1", a:test)
  call g:TU.equal(filename, breakpoint.file, "File should be set right", a:test)
  call g:TU.equal(1, breakpoint.line, "Line should be set right", a:test)
  " TODO: Find way to test sign
  call g:TU.equal(g:RubyDebugger.server.rdebug_pid, breakpoint.rdebug_pid, "Breakpoint should be assigned to running server", a:test)
  call g:TU.equal(1, breakpoint.debugger_id, "Breakpoint should get number from debugger", a:test)
  exe "close" 
endfunction





