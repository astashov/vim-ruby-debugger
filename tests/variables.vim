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


function! s:Tests.variables.test_should_open_variables_window(test)
  call g:RubyDebugger.send_command('var local')

  call g:RubyDebugger.open_variables()
  call g:TU.ok(s:variables_window.is_open(), "Variables window should opened", a:test)
  call g:TU.equal(bufwinnr("%"), s:variables_window.get_number(), "Focus should be into the variables window", a:test)
  call g:TU.equal(getline(1), s:variables_window.title, "First line should be name", a:test)
  call g:TU.match(getline(2), '|+self', "Second line should be 'self' variable", a:test)
  call g:TU.match(getline(3), '|-some_local', "Third line should be a local variable", a:test)
  call g:TU.match(getline(4), '|+array', "4-th line should be an array", a:test)
  call g:TU.match(getline(5), '`+hash', "5-th line should be a hash", a:test)

  exe 'close'
endfunction


function! s:Tests.variables.test_should_close_variables_window_after_opening(test)
  call g:RubyDebugger.send_command('var local')

  call g:RubyDebugger.open_variables()
  call g:RubyDebugger.open_variables()
  call g:TU.ok(!s:variables_window.is_open(), "Variables window should be closed", a:test)
endfunction


function! s:Tests.variables.test_should_open_instance_subvariable(test)
  call g:RubyDebugger.send_command('var local')
  call g:RubyDebugger.open_variables()
  exe 'normal 2G'

  call s:window_variables_activate_node()
  call g:TU.ok(s:variables_window.is_open(), "Variables window should opened", a:test)
  call g:TU.match(getline(2), '|\~self', "Second line should be opened 'self' variable", a:test)
  call g:TU.match(getline(3), '| |+self_array', "Third line should be closed array subvariable", a:test)
  call g:TU.match(getline(4), '| `-self_local', "4-th line should be local subvariable", a:test)
  call g:TU.match(getline(5), '|-some_local', "5-th line should be array variable", a:test)

  exe 'close'
endfunction


function! s:Tests.variables.test_should_close_instance_subvariable(test)
  call g:RubyDebugger.send_command('var local')
  call g:RubyDebugger.open_variables()
  exe 'normal 2G'

  call s:window_variables_activate_node()
  call s:window_variables_activate_node()
  call g:TU.ok(s:variables_window.is_open(), "Variables window should opened", a:test)
  call g:TU.match(getline(2), '|+self', "Second line should be closed 'self' variable", a:test)

  exe 'close'
endfunction


function! s:Tests.variables.test_should_open_last_variable_in_list(test)
  call g:RubyDebugger.send_command('var local')
  call g:RubyDebugger.open_variables()
  exe 'normal 5G'

  call s:window_variables_activate_node()
  call g:TU.match(getline(5), '`\~hash', "5-th line should be opened hash", a:test)
  call g:TU.match(getline(6), '  |-hash_local', "6 line should be local subvariable", a:test)
  call g:TU.match(getline(7), '  `+hash_array', "7-th line should be array subvariable", a:test)

  exe 'close'
endfunction


