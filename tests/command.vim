let s:Tests.command = {}

function! s:Tests.command.before_all()
  call s:Mock.mock_debugger()
endfunction


function! s:Tests.command.after_all()
    call s:Mock.unmock_debugger()
endfunction


function! s:Tests.command.test_some_user_command(test)
  call g:RubyDebugger.send_command("p \"all users\"") 
  call g:TU.equal(1, s:Mock.evals, "It should return eval command", a:test)
endfunction


