" *** VarParent class (start)

" Inherits VarParent from VarChild
let s:VarParent = copy(s:VarChild)

" ** Public methods


" Initializes new variable with childs
function! s:VarParent.new(attrs)
  if !has_key(a:attrs, 'hasChildren') || a:attrs['hasChildren'] != 'true'
    throw "RubyDebug: VarParent must be initialized with hasChildren = true"
  endif
  let new_variable = copy(self)
  let new_variable.attributes = a:attrs
  let new_variable.parent = {}
  let new_variable.is_open = 0
  let new_variable.level = 0
  let new_variable.children = []
  let new_variable.type = "VarParent"
  let s:Var.id += 1
  let new_variable.id = s:Var.id
  return new_variable
endfunction


" Open variable, init its children and display them
function! s:VarParent.open()
  let self.is_open = 1
  call self._init_children()
  return 0
endfunction


" Close variable and display it
function! s:VarParent.close()
  let self.is_open = 0
  call s:variables_window.display()
  if has_key(g:RubyDebugger, "current_variable")
    unlet g:RubyDebugger.current_variable
  endif
  return 0
endfunction


" Renders data of the variable
function! s:VarParent.render()
  return self._render(0, 0, [], len(self.children) ==# 1)
endfunction



" Add childs to the variable. You always should use this method instead of
" explicit assigning to children property (like 'add(self.children, variables)')
function! s:VarParent.add_childs(childs)
  " If children are given by array, extend self.children by this array
  if type(a:childs) == type([])
    for child in a:childs
      let child.parent = self
      let child.level = self.level + 1
    endfor
    call extend(self.children, a:childs)
  else
    " Otherwise, add child to self.children
    let a:childs.parent = self
    let child.level = self.level + 1
    call add(self.children, a:childs)
  end
endfunction


" Find and return variable by given Dict of attrs, e.g.: {'name' : 'var1'}
" If current variable doesn't match these attributes, try to find in children
function! s:VarParent.find_variable(attrs)
  if self._match_attributes(a:attrs)
    return self
  else
    for child in self.children
      let result = child.find_variable(a:attrs)
      if result != {}
        return result
      endif
    endfor
  endif
  return {}
endfunction


" Find and return array of variables that match given Dict of attrs.
" Try to match current variable and its children
function! s:VarParent.find_variables(attrs)
  let variables = []
  if self._match_attributes(a:attrs)
    call add(variables, self)
  endif
  for child in self.children
    call extend(variables, child.find_variables(a:attrs))
  endfor
  return variables
endfunction


" ** Private methods


" Update children of the variable
function! s:VarParent._init_children()
  " Remove all the current child nodes
  let self.children = []

  " Get children
  if has_key(self.attributes, 'objectId')
    let g:RubyDebugger.current_variable = self
    call g:RubyDebugger.queue.add('var instance ' . self.attributes.objectId)
  endif

endfunction


" *** VarParent class (end)


