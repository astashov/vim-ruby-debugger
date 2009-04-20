let s:Var = {}

" This is a proxy method for creating new variable
function! s:Var.new(attrs)
  if has_key(a:attrs, 'hasChildren') && a:attrs['hasChildren'] == 'true'
    return s:VarParent.new(a:attrs)
  else
    return s:VarChild.new(a:attrs)
  end
endfunction


function! s:Var.get_selected()
  let line = getline(".") 
  let match = matchlist(line, '[| ]\+[+\-\~]\+\(.\{-}\)\s') 
  let name = get(match, 1)
  let variable = g:RubyDebugger.variables.list.find_variable({'name' : name})
  return variable
endfunction

