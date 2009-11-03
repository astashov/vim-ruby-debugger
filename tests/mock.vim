let s:Mock = { 'breakpoints': 0, 'evals': 0 }

function! s:mock_debugger(messages, ...)
  let commands = []
  let messages_array = split(a:messages, s:separator)
  for message in messages_array
    let cmd = ""
    if message =~ 'break'
      let matches = matchlist(message, 'break \(.*\):\(.*\)')
      let cmd = '<breakpointAdded no="1" location="' . matches[1] . ':' . matches[2] . '" />'
      let s:Mock.breakpoints += 1
    elseif message =~ 'delete'
      let matches = matchlist(message, 'delete \(.*\)')
      let cmd = '<breakpointDeleted no="' . matches[1] . '" />'
      let s:Mock.breakpoints -= 1
    elseif message =~ 'var local'
      let cmd = '<variables>'
      let cmd = cmd . '<variable name="self" kind="instance" value="Self" type="Object" hasChildren="true" objectId="-0x2418a904" />'
      let cmd = cmd . '<variable name="some_local" kind="local" value="bla" type="String" hasChildren="false" objectId="-0x2418a905" />'
      let cmd = cmd . '<variable name="array" kind="local" value="Array (2 element(s))" type="Array" hasChildren="true" objectId="-0x2418a906" />'
      let cmd = cmd . '<variable name="quoted_hash" kind="local" value="Hash (1 element(s))" type="Hash" hasChildren="true" objectId="-0x2418a914" />'
      let cmd = cmd . '<variable name="hash" kind="local" value="Hash (2 element(s))" type="Hash" hasChildren="true" objectId="-0x2418a907" />'
      let cmd = cmd . '</variables>'
    elseif message =~ 'var instance -0x2418a904'
      let cmd = '<variables>'
      let cmd = cmd . '<variable name="self_array" kind="local" value="Array (2 element(s))" type="Array" hasChildren="true" objectId="-0x2418a908" />'
      let cmd = cmd . '<variable name="self_local" kind="local" value="blabla" type="String" hasChildren="false" objectId="-0x2418a909" />'
      let cmd = cmd . '<variable name="array" kind="local" value="Array (2 element(s))" type="Array" hasChildren="true" objectId="-0x2418a916" />'
      let cmd = cmd . '</variables>'
    elseif message =~ 'var instance -0x2418a907'
      let cmd = '<variables>'
      let cmd = cmd . '<variable name="hash_local" kind="instance" value="Some string" type="String" hasChildren="false" objectId="-0x2418a910" />'
      let cmd = cmd . '<variable name="hash_array" kind="instance" value="Array (1 element(s))" type="Array" hasChildren="true" objectId="-0x2418a911" />'
      let cmd = cmd . '</variables>'
    elseif message =~ 'var instance -0x2418a906'
      let cmd = '<variables>'
      let cmd = cmd . '<variable name="[0]" kind="instance" value="[\.^bla$]" type="String" hasChildren="false" objectId="-0x2418a912" />'
      let cmd = cmd . '<variable name="[1]" kind="instance" value="Array (1 element(s))" type="Array" hasChildren="true" objectId="-0x2418a913" />'
      let cmd = cmd . '</variables>'
    elseif message =~ 'var instance -0x2418a914'
      let cmd = '<variables>'
      let cmd = cmd . "<variable name=\"'quoted'\" kind=\"instance\" value=\"String\" type=\"String\" hasChildren=\"false\" objectId=\"-0x2418a915\" />"
      let cmd = cmd . '</variables>'
    elseif message =~ 'var instance -0x2418a916'
      let cmd = '<variables>'
      let cmd = cmd . "<variable name=\"[0]\" kind=\"instance\" value=\"String\" type=\"String\" hasChildren=\"false\" objectId=\"-0x2418a917\" />"
      let cmd = cmd . '</variables>'
    elseif message =~ 'where'
      let filename = s:Mock.file
      let cmd = '<frames>'
      let cmd = cmd . "<frame no='1' file='" . filename . "' line='2' current='true' />"
      let cmd = cmd . "<frame no='2' file='" . filename . "' line='3' />"
      let cmd = cmd . '</frames>'
    elseif message =~ '^p '
      let p = matchlist(message, "^p \\(.*\\)")[1]
      let s:Mock.evals += 1
      let cmd = '<eval expression="' . p . '" value=""all users"" />'
    endif
    if cmd != ""
      call add(commands, cmd)
    endif
  endfor
  if !empty(commands)
    call writefile([ join(commands, s:separator) ], s:tmp_file)
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
  call delete(a:filename)
endfunction



