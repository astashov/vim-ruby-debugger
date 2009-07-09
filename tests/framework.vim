let TU = { 'output': '', 'errors': '', 'success': ''}


function! TU.run(...)
  call g:TU.init()
  for key in keys(s:Tests)
    " Run tests only if function was called without arguments, of argument ==
    " current tests group.
    if !a:0 || a:1 == key
      let g:TU.output = g:TU.output . "\n" . key . ":\n"
      if has_key(s:Tests[key], 'before_all')
        call s:Tests[key].before_all()
      endif
      for test in keys(s:Tests[key])
        if test =~ '^test_'
          if has_key(s:Tests[key], 'before')
            call s:Tests[key].before()
          endif
          call s:Tests[key][test](test)
          if has_key(s:Tests[key], 'after')
            call s:Tests[key].after()
          endif
        endif
      endfor
      if has_key(s:Tests[key], 'after_all')
        call s:Tests[key].after_all()
      endif
      let g:TU.output = g:TU.output . "\n"
    endif
  endfor

  call g:TU.show_output()
  call g:TU.restore()
endfunction


function! TU.init()
  let g:TU.breakpoint_id = s:Breakpoint.id 
  let s:Breakpoint.id = 0

  let g:TU.variables = g:RubyDebugger.variables 
  let g:RubyDebugger.variables = {}

  let g:TU.breakpoints = g:RubyDebugger.breakpoints 
  let g:RubyDebugger.breakpoints = []

  let g:TU.var_id = s:Var.id
  let s:Var.id = 0

  let s:Mock.breakpoints = 0
  let s:Mock.evals = 0

  if s:variables_window.is_open()
    call s:variables_window.close()
  endif
  if s:breakpoints_window.is_open()
    call s:breakpoints_window.close()
  endif

  let g:TU.output = ""
  let g:TU.success = ""
  let g:TU.errors = ""

  " For correct closing and deleting test files
  let g:TU.hidden = &hidden
  set nohidden
endfunction


function! TU.restore()
  let s:Breakpoint.id = g:TU.breakpoint_id
  unlet g:TU.breakpoint_id

  let g:RubyDebugger.variables = g:TU.variables 
  unlet g:TU.variables 

  let g:RubyDebugger.breakpoints = g:TU.breakpoints  
  unlet g:TU.breakpoints

  let s:Var.id = g:TU.var_id 
  unlet g:TU.var_id 

  let &hidden = g:TU.hidden
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


function! TU.match(expected, actual, description, test)
  if a:expected =~ a:actual
    let g:TU.output = g:TU.output . "."
    let g:TU.success = g:TU.success . a:test . ": " . a:description . ", match one to other\n"
  else
    let g:TU.output = g:TU.output . "F"
    let g:TU.errors = g:TU.errors . a:test . ": " . a:description . ", expected to match " . a:expected . ", got " . a:actual . ".\n"
  endif
endfunction


let s:Tests = {}
