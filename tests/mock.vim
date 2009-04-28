let s:Mock = { 'breakpoints': 0 }

function! s:mock_debugger(message)
  if a:message =~ 'break'
    let matches = matchlist(a:message, 'break \(.*\):\(.*\)')
    let cmd = '<breakpointAdded no="1" location="' . matches[1] . ':' . matches[2] . '" />'
    let s:Mock.breakpoints += 1
  endif
  call writefile([ cmd ], s:tmp_file)
  call g:RubyDebugger.receive_command()
endfunction

function! s:Mock.mock_debugger()
  let g:RubyDebugger.send_command = function("s:mock_debugger") 
endfunction

function! s:Mock.unmock_debugger()
  let g:RubyDebugger.send_command = function("s:send_message_to_debugger")
endfunction
