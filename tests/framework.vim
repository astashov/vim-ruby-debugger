let TU = { 'output': '', 'errors': '', 'success': ''}

function! TU.run()
  for key in keys(s:Tests)
    if key =~ '^test_'
      source s:runtime_dir . '/plugin/ruby_debugger_test.vim'
      call s:Tests.setup()
      call s:Tests[key]()
    endif
  endfor
  call TU.show_output()
endfunction


function! TU.show_output()
  echo TU.output
endfunction


function! TU.ok(condition, description, test)
  call TU._process(a:condition, a:description, a:test)
endfunction


function! TU.equal(expected, actual, description, test)
  call TU._process(a:expected == a:actual, a:description, a:test)
endfunction


function! TU._process(condition, description, test)
  if a:condition
    let TU.output += "."
    let TU.success += a:test . ": " . a:description . "\n"
  else
    let TU.output += "F"
    let TU.errors += a:test . ": " . a:description . "\n"
  endif
endfunction


let s:Tests = {}
