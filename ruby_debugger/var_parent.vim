" Inherits VarParent from VarChild
let s:VarParent = copy(s:VarChild)


" Initializes new variable with childs
function! s:VarParent.new(attrs)
  if !has_key(a:attrs, 'hasChildren') || a:attrs['hasChildren'] != 'true'
    throw "RubyDebug: VarParent must be initialized with hasChild = true"
  endif
  let new_variable = copy(self)
  let new_variable.attributes = a:attrs
  let new_variable.parent = {}
  let new_variable.is_open = 0
  let new_variable.children = []
  return new_variable
endfunction


function! s:VarParent.open()
  let self.is_open = 1
  if self.children ==# []
    " return self._init_children(0)
  else
    return 0
  endif
endfunction


function! s:VarParent.add_childs(childs)
  if type(a:childs) == type([])
    call extend(self.children, a:childs)
  else
    call add(self.children, a:childs)
  end
endfunction



