let s:Tests.breakpoint = {}

function! s:Tests.breakpoint.before_all()
  exe "Rdebugger"
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.breakpoint.after_all()
  call s:Server._stop_server('localhost', s:rdebug_port)
  call s:Server._stop_server('localhost', s:debugger_port)
  call s:Mock.unmock_debugger()
endfunction


function! s:Tests.breakpoint.test_should_set_breakpoint(test)

endfunction





