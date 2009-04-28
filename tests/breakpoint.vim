let s:Tests.breakpoint = {}

function! s:Tests.breakpoint.before_all()
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.breakpoint.after_all()
    call s:Mock.unmock_debugger()
endfunction


function! s:Tests.breakpoint.before()
  let s:Breakpoint.id = 0
  let g:RubyDebugger.breakpoints = []
  let g:RubyDebugger.variables = {} 
  call s:Server._stop_server('localhost', s:rdebug_port)
  call s:Server._stop_server('localhost', s:debugger_port)
endfunction


function! s:Tests.breakpoint.test_should_set_breakpoint(test)
  exe "Rdebugger"
  let filename = s:runtime_dir . "/tmp/ruby_debugger_test_file"
  exe "new " . filename
  exe "write"
  call g:RubyDebugger.set_breakpoint()
  let breakpoint = get(g:RubyDebugger.breakpoints, 0)
  call g:TU.equal(1, breakpoint.id, "Id of first breakpoint should == 1", a:test)
  call g:TU.equal(filename, breakpoint.file, "File should be set right", a:test)
  call g:TU.equal(1, breakpoint.line, "Line should be set right", a:test)
  " TODO: Find way to test sign
  call g:TU.equal(g:RubyDebugger.server.rdebug_pid, breakpoint.rdebug_pid, "Breakpoint should be assigned to running server", a:test)
  call g:TU.equal(1, breakpoint.debugger_id, "Breakpoint should get number from debugger", a:test)
  silent exe "close" 
  silent exe "!rm " . filename
endfunction


function! s:Tests.breakpoint.test_should_add_all_unassigned_breakpoints_to_running_server(test)
  let filename = s:runtime_dir . "/tmp/ruby_debugger_test_file"
  
  " Write 3 lines of text and set 3 breakpoints (on every line)
  exe "new " . filename
  exe "normal iblablabla"
  exe "normal oblabla" 
  exe "normal obla" 
  exe "normal gg"
  exe "write"
  call g:RubyDebugger.set_breakpoint()
  exe "normal j"
  call g:RubyDebugger.set_breakpoint()
  exe "normal j"
  call g:RubyDebugger.set_breakpoint()

  " Lets suggest that some breakpoint was assigned to old server
  let g:RubyDebugger.breakpoints[1].rdebug_pid = 'bla'

  call g:TU.equal(3, len(g:RubyDebugger.breakpoints), "3 breakpoints should be set", a:test)
  exe "Rdebugger"
  call g:TU.equal(3, s:Mock.breakpoints, "3 breakpoints should be assigned", a:test)
  for breakpoint in g:RubyDebugger.breakpoints
    call g:TU.equal(g:RubyDebugger.server.rdebug_pid, breakpoint.rdebug_pid, "Breakpoint should have PID of running server", a:test)
  endfor
  silent exe "close"
  silent exe "!rm " . filename
endfunction

  
function! s:Tests.breakpoint.test_jump_to_breakpoint_by_breakpoint(test)
  call s:Tests.breakpoint.jump_to_breakpoint('breakpoint', a:test)
endfunction


function! s:Tests.breakpoint.test_jump_to_breakpoint_by_suspended(test)
  call s:Tests.breakpoint.jump_to_breakpoint('suspended', a:test)
endfunction


function! s:Tests.breakpoint.jump_to_breakpoint(cmd, test)
  let filename = s:runtime_dir . "/tmp/ruby_debugger_test_file"
  
  " Write 2 lines and set current line to second line. We will jump to first
  " line
  exe "new " . filename
  exe "normal iblablabla"
  exe "normal oblabla" 
  exe "write"

  call g:TU.equal(2, line("."), "Current line before jumping is second", a:test)

  let cmd = '<' . a:cmd . ' file="' . filename . '" line="1" />'
  call writefile([ cmd ], s:tmp_file)
  call g:RubyDebugger.receive_command()

  call g:TU.equal(1, line("."), "Current line before jumping is first", a:test)
  call g:TU.equal(filename, expand("%"), "Jumped to correct file", a:test)

  silent exe "close"
  silent exe "!rm " . filename
endfunction

