let s:Tests.breakpoint = {}

function! s:Tests.breakpoint.before_all()
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.breakpoint.after_all()
  call s:Mock.unmock_debugger()
endfunction


function! s:Tests.breakpoint.before()
  let s:Breakpoint.id = 0
  let g:RubyDebugger.frames = []
  let g:RubyDebugger.exceptions = []
  let g:RubyDebugger.breakpoints = []
  let g:RubyDebugger.variables = {} 
  call g:RubyDebugger.queue.empty() 
  call s:Server._stop_server(s:rdebug_port)
  call s:Server._stop_server(s:debugger_port)
  silent exe "only"
endfunction


function! s:Tests.breakpoint.test_should_set_breakpoint(test)
  exe "Rdebugger"
  let filename = s:Mock.mock_file()
  let file_pattern = substitute(filename, '[\/\\]', '[\\\/\\\\]', "g")

  call g:RubyDebugger.toggle_breakpoint()
  let breakpoint = get(g:RubyDebugger.breakpoints, 0)
  call g:TU.equal(1, breakpoint.id, "Id of first breakpoint should == 1", a:test)
  call g:TU.match(breakpoint.file, file_pattern, "File should be set right", a:test)
  call g:TU.equal(1, breakpoint.line, "Line should be set right", a:test)
  " TODO: Find way to test sign
  call g:TU.equal(g:RubyDebugger.server.rdebug_pid, breakpoint.rdebug_pid, "Breakpoint should be assigned to running server", a:test)
  call g:TU.equal(1, breakpoint.debugger_id, "Breakpoint should get number from debugger", a:test)
  call s:Mock.unmock_file(filename)
endfunction


function! s:Tests.breakpoint.test_should_add_all_unassigned_breakpoints_to_running_server(test)
  let filename = s:Mock.mock_file()
  " Write 3 lines of text and set 3 breakpoints (on every line)
  exe "normal iblablabla"
  exe "normal oblabla" 
  exe "normal obla" 
  exe "normal gg"
  exe "write"
  call g:RubyDebugger.toggle_breakpoint()
  exe "normal j"
  call g:RubyDebugger.toggle_breakpoint()
  exe "normal j"
  call g:RubyDebugger.toggle_breakpoint()

  " Lets suggest that some breakpoint was assigned to old server
  let g:RubyDebugger.breakpoints[1].rdebug_pid = 'bla'

  call g:TU.equal(3, len(g:RubyDebugger.breakpoints), "3 breakpoints should be set", a:test)
  exe "Rdebugger"
  call g:TU.equal(3, s:Mock.breakpoints, "3 breakpoints should be assigned", a:test)
  for breakpoint in g:RubyDebugger.breakpoints
    call g:TU.equal(g:RubyDebugger.server.rdebug_pid, breakpoint.rdebug_pid, "Breakpoint should have PID of running server", a:test)
  endfor
  call s:Mock.unmock_file(filename)
endfunction


function! s:Tests.breakpoint.test_should_remove_all_breakpoints(test)
  let filename = s:Mock.mock_file()
  " Write 3 lines of text and set 3 breakpoints (on every line)
  exe "normal iblablabla"
  exe "normal oblabla" 
  exe "normal obla" 
  exe "normal gg"
  exe "write"
  call g:RubyDebugger.toggle_breakpoint()
  exe "normal j"
  call g:RubyDebugger.toggle_breakpoint()
  exe "normal j"
  call g:RubyDebugger.toggle_breakpoint()
  call g:TU.equal(3, len(g:RubyDebugger.breakpoints), "3 breakpoints should be set", a:test)
  
  call g:RubyDebugger.remove_breakpoints()

  call g:TU.equal(0, len(g:RubyDebugger.breakpoints), "Breakpoints should be removed", a:test)

  call s:Mock.unmock_file(filename)
endfunction

  
function! s:Tests.breakpoint.test_jump_to_breakpoint_by_breakpoint(test)
  call s:Tests.breakpoint.jump_to_breakpoint('breakpoint', a:test)
endfunction


function! s:Tests.breakpoint.test_jump_to_breakpoint_by_suspended(test)
  call s:Tests.breakpoint.jump_to_breakpoint('suspended', a:test)
endfunction


function! s:Tests.breakpoint.test_delete_breakpoint(test)
  exe "Rdebugger"
  let filename = s:Mock.mock_file()
  call g:RubyDebugger.toggle_breakpoint()
  call g:RubyDebugger.toggle_breakpoint()

  call g:TU.ok(empty(g:RubyDebugger.breakpoints), "Breakpoint should be removed", a:test)
  call g:TU.equal(0, s:Mock.breakpoints, "0 breakpoints should be assigned", a:test)

  call s:Mock.unmock_file(filename)
endfunction


function! s:Tests.breakpoint.jump_to_breakpoint(cmd, test)
  let filename = s:Mock.mock_file()
  let file_pattern = substitute(filename, '[\/\\]', '[\\\/\\\\]', "g")
  
  " Write 2 lines and set current line to second line. We will jump to first
  " line
  exe "normal iblablabla"
  exe "normal oblabla" 
  exe "write"

  call g:TU.equal(2, line("."), "Current line before jumping is second", a:test)

  let cmd = '<' . a:cmd . ' file="' . filename . '" line="1" />'
  call writefile([ cmd ], s:tmp_file)
  call g:RubyDebugger.receive_command()

  call g:TU.equal(1, line("."), "Current line before jumping is first", a:test)
  call g:TU.match(expand("%"), file_pattern, "Jumped to correct file", a:test)

  call s:Mock.unmock_file(filename)
endfunction


function! s:Tests.breakpoint.test_should_open_window_without_got_breakpoints(test)
  call g:RubyDebugger.open_breakpoints()

  call g:TU.ok(s:breakpoints_window.is_open(), "Breakpoints window should opened", a:test)
  call g:TU.equal(bufwinnr("%"), s:breakpoints_window.get_number(), "Focus should be into the breakpoints window", a:test)
  call g:TU.equal(getline(1), s:breakpoints_window.title, "First line should be name", a:test)

  exe 'close'
endfunction


function! s:Tests.breakpoint.test_should_open_window_and_show_breakpoints(test)
  let filename = s:Mock.mock_file()
  " Replace all windows separators (\) and POSIX separators (/) to [\/] for
  " making it cross-platform
  let file_pattern = substitute(filename, '[\/\\]', '[\\\/\\\\]', "g")
  " Write 2 lines of text and set 2 breakpoints (on every line)
  exe "normal iblablabla"
  exe "normal oblabla" 
  exe "normal gg"
  exe "write"
  call g:RubyDebugger.toggle_breakpoint()
  exe "normal j"
  call g:RubyDebugger.toggle_breakpoint()

  call s:Mock.unmock_file(filename)

  " Lets suggest that some breakpoint is assigned
  let g:RubyDebugger.breakpoints[1].debugger_id = 4

  call g:RubyDebugger.open_breakpoints()
  call g:TU.match(getline(2), '1  ' . file_pattern . ':1', "Should show first breakpoint", a:test)
  call g:TU.match(getline(3), '2 4 ' . file_pattern . ':2', "Should show second breakpoint", a:test)

  exe 'close'
endfunction


function! s:Tests.breakpoint.test_should_open_selected_breakpoint_from_breakpoints_window(test)
  let filename = s:Mock.mock_file()
  let file_pattern = substitute(filename, '[\/\\]', '[\\\/\\\\]', "g")
  exe "normal iblablabla"
  exe "normal oblabla" 
  call g:RubyDebugger.toggle_breakpoint()
  exe "normal gg"
  exe "write"
  exe "wincmd w"
  exe "new"

  call g:TU.ok(expand("%") != filename, "It should not be within the file with breakpoint", a:test)
  call g:RubyDebugger.open_breakpoints()
  exe 'normal 2G'
  call s:window_breakpoints_activate_node()
  call g:TU.match(expand("%"), file_pattern, "It should open file with breakpoint", a:test)
  call g:TU.equal(2, line("."), "It should jump to line with breakpoint", a:test)
  call g:RubyDebugger.open_breakpoints()

  call s:Mock.unmock_file(filename)
endfunction


function! s:Tests.breakpoint.test_should_delete_breakpoint_from_breakpoints_window(test)
  let filename = s:Mock.mock_file()
  call g:RubyDebugger.toggle_breakpoint()
  call s:Mock.unmock_file(filename)
  call g:TU.ok(!empty(g:RubyDebugger.breakpoints), "Breakpoint should be set", a:test)

  call g:RubyDebugger.open_breakpoints()
  exe 'normal 2G'
  call s:window_breakpoints_delete_node()
  call g:TU.equal('', getline(2), "Breakpoint should not be shown", a:test)
  call g:TU.ok(empty(g:RubyDebugger.breakpoints), "Breakpoint should be destroyed", a:test)

  exe 'close'
endfunction


