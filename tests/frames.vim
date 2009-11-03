let s:Tests.frames = {}

function! s:Tests.frames.before_all()
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.frames.after_all()
  call s:Mock.unmock_debugger()
endfunction


function! s:Tests.frames.before()
  let s:Breakpoint.id = 0
  let g:RubyDebugger.frames = []
  let g:RubyDebugger.variables = {} 
  call g:RubyDebugger.queue.empty() 
  call s:Server._stop_server(s:rdebug_port)
  call s:Server._stop_server(s:debugger_port)
endfunction


function! s:Tests.frames.test_should_display_frames_in_window_frames(test)
  let filename = s:Mock.mock_file()
  " Replace all windows separators (\) and POSIX separators (/) to [\/] for
  " making it cross-platform
  let file_pattern = substitute(filename, '[\/\\]', '[\\\/\\\\]', "g")
  let s:Mock.file = filename
  call g:RubyDebugger.send_command('where')

  call g:RubyDebugger.open_frames()
  call g:TU.match(getline(2), '1 Current ' . file_pattern . ':2', "Should show first frame", a:test)
  call g:TU.match(getline(3), '2 ' . file_pattern . ':3', "Should show second frame", a:test)

  exe 'close'
endfunction


function! s:Tests.frames.test_should_open_file_with_frame(test)
  let filename = s:Mock.mock_file()
  let file_pattern = substitute(filename, '[\/\\]', '[\\\/\\\\]', "g")
  let s:Mock.file = filename
  " Write 3 lines of text and set 3 frames (on every line)
  exe "normal iblablabla"
  exe "normal oblabla" 
  exe "normal obla" 
  exe "normal gg"
  exe "write"
  exe "wincmd w"
  call g:TU.ok(expand("%") != filename, "It should not be within the file with frame", a:test)

  call g:RubyDebugger.send_command('where')
  call g:TU.equal(2, len(g:RubyDebugger.frames), "2 frames should be set", a:test)

  call g:RubyDebugger.open_frames()
  exe 'normal 3G'
  call s:window_frames_activate_node()
  call g:TU.match(expand("%"), file_pattern, "It should open file with frame", a:test)
  call g:TU.equal(3, line("."), "It should jump to line with frame", a:test)
  call g:RubyDebugger.open_frames()

  call s:Mock.unmock_file(filename)
endfunction


function! s:Tests.frames.test_should_clear_frames_after_movement_command(test)
  let g:RubyDebugger.frames = [{ 'bla' : 'bla' }]
  call g:RubyDebugger.next()
  call g:TU.equal([], g:RubyDebugger.frames, "Frames should be cleaned", a:test)

  let g:RubyDebugger.frames = [{ 'bla' : 'bla' }]
  call g:RubyDebugger.step()
  call g:TU.equal([], g:RubyDebugger.frames, "Frames should be cleaned", a:test)

  let g:RubyDebugger.frames = [{ 'bla' : 'bla' }]
  call g:RubyDebugger.continue()
  call g:TU.equal([], g:RubyDebugger.frames, "Frames should be cleaned", a:test)

  let g:RubyDebugger.frames = [{ 'bla' : 'bla' }]
  call g:RubyDebugger.exit()
  call g:TU.equal([], g:RubyDebugger.frames, "Frames should be cleaned", a:test)
endfunction



