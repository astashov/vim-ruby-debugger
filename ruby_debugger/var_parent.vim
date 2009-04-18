" Inherits VarParent from VarChild
let s:VarParent = copy(s:VarChild)


" Renders data of the variable
function! s:VarParent.render()
  return self._render(0, 0, [], len(self.children) ==# 1)
endfunction



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
  let new_variable.type = "VarParent"
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
    for child in a:childs
      let child.parent = self
    endfor
    call extend(self.children, a:childs)
  else
    let a:childs.parent = self
    call add(self.children, a:childs)
  end
endfunction



