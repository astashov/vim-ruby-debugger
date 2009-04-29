let s:Mock = { 'breakpoints': 0 }

function! s:mock_debugger(message)
  let cmd = ""
  if a:message =~ 'break'
    let matches = matchlist(a:message, 'break \(.*\):\(.*\)')
    let cmd = '<breakpointAdded no="1" location="' . matches[1] . ':' . matches[2] . '" />'
    let s:Mock.breakpoints += 1
  elseif a:message =~ 'var local'
    let cmd = '<variables>'
    let cmd = cmd . '<variable name="self" kind="instance" value="Self" type="Object" hasChildren="true" objectId="-0x2418a904" />'
    let cmd = cmd . '<variable name="some_local" kind="local" value="bla" type="String" hasChildren="false" objectId="-0x2418a905" />'
    let cmd = cmd . '<variable name="array" kind="local" value="Array (2 element(s))" type="Array" hasChildren="true" objectId="-0x2418a906" />'
    let cmd = cmd . '<variable name="hash" kind="local" value="Hash (2 element(s))" type="Hash" hasChildren="true" objectId="-0x2418a907" />'
    let cmd = cmd . '</variables>'
  endif
  if cmd != "" 
    call writefile([ cmd ], s:tmp_file)
    call g:RubyDebugger.receive_command()
  endif
endfunction


function! s:Mock.mock_debugger()
  let g:RubyDebugger.send_command = function("s:mock_debugger") 
endfunction


function! s:Mock.unmock_debugger()
  let g:RubyDebugger.send_command = function("s:send_message_to_debugger")
endfunction


function! s:Mock.mock_file()
  let filename = s:runtime_dir . "/tmp/ruby_debugger_test_file"
  exe "new " . filename
  exe "write"
  return filename
endfunction


function! s:Mock.unmock_file(filename)
  silent exe "close"
  silent exe "!rm " . a:filename
endfunction



