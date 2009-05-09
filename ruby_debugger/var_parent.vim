" Inherits VarParent from VarChild
let s:VarParent = copy(s:VarChild)


" Renders data of the variable
function! s:VarParent.render()
  return self._render(0, 0, [], len(self.children) ==# 1)
endfunction



" Initializes new variable with childs
function! s:VarParent.new(attrs)
  if !has_key(a:attrs, 'hasChildren') || a:attrs['hasChildren'] != 'true'
    throw "RubyDebug: VarParent must be initialized with hasChildren = true"
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
  call self._init_children()
  return 0
endfunction


function! s:VarParent.close()
  let self.is_open = 0
  call s:variables_window.display()
  if has_key(g:RubyDebugger, "current_variable")
    unlet g:RubyDebugger.current_variable
  endif
  return 0
endfunction



function! s:VarParent._init_children()
  "remove all the current child nodes
  let self.children = []
  if !has_key(self.attributes, "name")
    return 0
  endif

  if has_key(self.attributes, 'objectId')
    let g:RubyDebugger.current_variable = self
    call g:RubyDebugger.send_command('var instance ' . self.attributes.objectId)
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


function! s:VarParent.find_variable(...)
  let match_attributes = a:0 > 1 ? self._match_attributes(a:1, a:2) : self._match_attributes(a:1)
  if match_attributes
    return self
  else
    for child in self.children
      let result = a:0 > 1 ? child.find_variable(a:1, a:2) : child.find_variable(a:1)
      if result != {}
        return result
      endif
    endfor
  endif
  return {}
endfunction

