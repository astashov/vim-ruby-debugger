let TU = { 'output': '', 'errors': '', 'success': ''}

function! TU.run()
  for key in keys(s:Tests)
    let g:TU.output = g:TU.output . "\n" . key . ":\n"
    for test in keys(s:Tests[key])
      if test =~ '^test_'
        call s:Tests[key].setup()
        call s:Tests[key][test](test)
      endif
    endfor
    let g:TU.output = g:TU.output . "\n"
  endfor
  call g:TU.show_output()
endfunction


function! TU.show_output()
  echo g:TU.output . "\n" . g:TU.errors
endfunction


function! TU.ok(condition, description, test)
  if a:condition
    let g:TU.output = g:TU.output . "."
    let g:TU.success = g:TU.success . a:test . ": " . a:description . ", true\n"
  else
    let g:TU.output = g:TU.output . "F"
    let g:TU.errors = g:TU.errors . a:test . ": " . a:description . ", expected true, got false.\n"
  endif
endfunction


function! TU.equal(expected, actual, description, test)
  if a:expected == a:actual
    let g:TU.output = g:TU.output . "."
    let g:TU.success = g:TU.success . a:test . ": " . a:description . ", equals\n"
  else
    let g:TU.output = g:TU.output . "F"
    let g:TU.errors = g:TU.errors . a:test . ": " . a:description . ", expected " . a:expected . ", got " . a:actual . ".\n"
  endif
endfunction


let s:Tests = {}
