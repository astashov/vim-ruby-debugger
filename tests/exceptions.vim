let s:Tests.exceptions = {}

function! s:Tests.exceptions.before_all()
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.exceptions.after_all()
  call s:Mock.unmock_debugger()
endfunction


function! s:Tests.exceptions.before()
  let s:Breakpoint.id = 0
  let g:RubyDebugger.frames = []
  let g:RubyDebugger.exceptions = []
  let g:RubyDebugger.variables = {} 
  call g:RubyDebugger.queue.empty() 
  call s:Server._stop_server(s:rdebug_port)
  call s:Server._stop_server(s:debugger_port)
endfunction


function! s:Tests.exceptions.test_should_not_set_exception_catcher_if_debugger_is_not_running(test)
  call g:RubyDebugger.catch_exception("NameError")
  call g:TU.equal(0, len(g:RubyDebugger.exceptions), "Exception catcher should not be set", a:test)
endfunction


function! s:Tests.exceptions.test_should_clear_exceptions_after_restarting_debugger(test)
  exe "Rdebugger"
  call g:RubyDebugger.catch_exception("NameError")
  call g:TU.equal(1, len(g:RubyDebugger.exceptions), "Exception should be set after starting the server", a:test)
  exe "Rdebugger"
  call g:TU.equal(0, len(g:RubyDebugger.exceptions), "Exception should be cleared after restarting the server", a:test)
endfunction


function! s:Tests.exceptions.test_should_display_exceptions_in_window_breakpoints(test)
  exe "Rdebugger"
  call g:RubyDebugger.catch_exception("NameError")
  call g:RubyDebugger.catch_exception("ArgumentError")
  call g:RubyDebugger.open_breakpoints()
  call g:TU.match('Exception breakpoints: NameError, ArgumentError', getline(3), "Should show exception breakpoints", a:test)
  exe 'close'
endfunction



