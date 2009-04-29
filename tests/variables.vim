let s:Tests.variables = {}

function! s:Tests.variables.before_all()
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.variables.after_all()
  call s:Mock.unmock_debugger()
endfunction


function! s:Tests.variables.before()
  let g:RubyDebugger.breakpoints = []
  let g:RubyDebugger.variables = {} 
  call s:Server._stop_server('localhost', s:rdebug_port)
  call s:Server._stop_server('localhost', s:debugger_port)
endfunction


function! s:Tests.variables.test_should_not_open_window_without_got_variables(test)
  call g:RubyDebugger.open_variables()
  " It should not be opened
  call g:TU.ok(!s:variables_window.is_open(), "Variables window should not be opened", a:test)
endfunction


function! s:Tests.variables.test_should_init_variables_after_breakpoint(test)
  let filename = s:Mock.mock_file()
  
  let cmd = '<breakpoint file="' . filename . '" line="1" />'
  call writefile([ cmd ], s:tmp_file)
  call g:RubyDebugger.receive_command()

  call g:TU.equal("VarParent", g:RubyDebugger.variables.type, "Root variable should be initialized", a:test)
  call g:TU.equal(4, len(g:RubyDebugger.variables.children), "4 variables should be initialized", a:test)
  call g:TU.equal(3, len(filter(copy(g:RubyDebugger.variables.children), 'v:val.type == "VarParent"')), "3 Parent variables should be initialized", a:test)
  call g:TU.equal(1, len(filter(copy(g:RubyDebugger.variables.children), 'v:val.type == "VarChild"')), "1 Child variable should be initialized", a:test)

  call s:Mock.unmock_file(filename)
endfunction

  " It should execute 'var local' after jumping to breakpoint

"  call WindowVaribalies.toggle()
"
"
"
"  call s:Mock.ummock_file(filename)
