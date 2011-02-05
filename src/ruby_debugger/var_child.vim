" *** VarChild class (start)

let s:VarChild = {}

" ** Public methods

" Constructs new variable without childs
function! s:VarChild.new(attrs)
  let new_variable = copy(self)
  let new_variable.attributes = a:attrs
  let new_variable.parent = {}
  let new_variable.level = 0
  let new_variable.type = "VarChild"
  let s:Var.id += 1
  let new_variable.id = s:Var.id
  return new_variable
endfunction


" Renders data of the variable
function! s:VarChild.render()
  return self._render(0, 0, [], len(self.parent.children) ==# 1)
endfunction


" VarChild can't be opened because it can't have children. But VarParent can
function! s:VarChild.open()
  return 0
endfunction


" VarChild can't be closed because it can't have children. But VarParent can
function! s:VarChild.close()
  return 0
endfunction


" VarChild can't be parent. But VarParent can. If Var have hasChildren ==
" true, then it is parent
function! s:VarChild.is_parent()
  return has_key(self.attributes, 'hasChildren') && get(self.attributes, 'hasChildren') ==# 'true'
endfunction


" Output format for Variables Window
function! s:VarChild.to_s()
  return get(self.attributes, "name", "undefined") . "\t" . get(self.attributes, "type", "undefined") . "\t" . get(self.attributes, "value", "undefined") . "\t" . get(self, "id", "0")
endfunction


" Find and return variable by given Dict of attrs, e.g.: {'name' : 'var1'}
function! s:VarChild.find_variable(attrs)
  if self._match_attributes(a:attrs)
    return self
  else
    return {}
  endif
endfunction


" Find and return array of variables that match given Dict of attrs
function! s:VarChild.find_variables(attrs)
  let variables = []
  if self._match_attributes(a:attrs)
    call add(variables, self)
  endif
  return variables
endfunction


" ** Private methods


" Recursive function, that renders Variable and all its childs (if they are
" presented). Stolen from NERDTree
function! s:VarChild._render(depth, draw_text, vertical_map, is_last_child)
  let output = ""
  if a:draw_text ==# 1
    let tree_parts = ''

    " get all the leading spaces and vertical tree parts for this line
    if a:depth > 1
      for j in a:vertical_map[0:-2]
        if j ==# 1
          let tree_parts = tree_parts . '| '
        else
          let tree_parts = tree_parts . '  '
        endif
      endfor
    endif
    
    " get the last vertical tree part for this line which will be different
    " if this node is the last child of its parent
    if a:is_last_child
      let tree_parts = tree_parts . '`'
    else
      let tree_parts = tree_parts . '|'
    endif

    " smack the appropriate dir/file symbol on the line before the file/dir
    " name itself
    if self.is_parent()
      if self.is_open
        let tree_parts = tree_parts . '~'
      else
        let tree_parts = tree_parts . '+'
      endif
    else
      let tree_parts = tree_parts . '-'
    endif
    let line = tree_parts . self.to_s()
    let output = output . line . "\n"

  endif

  if self.is_parent() && self.is_open
    if len(self.children) > 0

      " draw all the nodes children except the last
      let last_index = len(self.children) - 1
      if last_index > 0
        for i in self.children[0:last_index - 1]
          let output = output . i._render(a:depth + 1, 1, add(copy(a:vertical_map), 1), 0)
        endfor
      endif

      " draw the last child, indicating that it IS the last
      let output = output . self.children[last_index]._render(a:depth + 1, 1, add(copy(a:vertical_map), 0), 1)

    endif
  endif

  return output

endfunction


" Return 1 if *all* given attributes (pairs key/value) match to current
" variable
function! s:VarChild._match_attributes(attrs)
  let conditions = 1
  for attr in keys(a:attrs)
    if has_key(self.attributes, attr)
      " If current key is contained in attributes of variable (they were
      " attributes in <variable /> tag, then trying to match there.
      let conditions = conditions && self.attributes[attr] == a:attrs[attr] 
    elseif has_key(self, attr)
      " Otherwise, if current key is contained in auxiliary attributes of the
      " variable, trying to match there
      let conditions = conditions && self[attr] == a:attrs[attr]
    else
      " Otherwise, this variable is not match
      let conditions = 0
      break
    endif
  endfor
  return conditions
endfunction


" *** VarChild class (end)



