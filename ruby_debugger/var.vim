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
  let match = matchlist(line, '.*\t\(.*\)$') 
  let id = get(match, 1)
  if id
    let tree_part = matchlist(line, '[| ]\+')[0]
    if len(tree_part) > 1
      let line_number = line(".")
      let tree_part = strpart(tree_part, 2)
      while match(getline(line_number), '^' . tree_part . '\~') == -1
        let line_number -= 1
      endwhile
      let line = getline(line_number) 
      let match = matchlist(line, '.*\t\(.*\)$') 
      let parent_id = get(match, 1)
      let variable = g:RubyDebugger.variables.find_variable({'objectId' : id}, {'objectId' : parent_id})
    else
      let variable = g:RubyDebugger.variables.find_variable({'objectId' : id})
    endif
    return variable
  else
    return {}
  endif
endfunction

