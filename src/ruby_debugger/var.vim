" *** Var proxy class (start)

let s:Var = { 'id' : 0 }

" ** Public methods

" This is a proxy method for creating new variable
function! s:Var.new(attrs)
  if has_key(a:attrs, 'hasChildren') && a:attrs['hasChildren'] == 'true'
    return s:VarParent.new(a:attrs)
  else
    return s:VarChild.new(a:attrs)
  end
endfunction


" Get variable under cursor
function! s:Var.get_selected()
  let line = getline(".")
  " Get its id - it is last in the string
  let match = matchlist(line, '.*\t\(\d\+\)$')
  let id = get(match, 1)
  if id
    let variable = g:RubyDebugger.variables.find_variable({'id' : id})
    return variable
  else
    return {}
  endif
endfunction


" *** Var proxy class (end)


