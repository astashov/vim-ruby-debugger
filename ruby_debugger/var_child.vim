" *** Start of variables ***
let s:VarChild = {}


" Initializes new variable without childs
function! s:VarChild.new(attrs)
  let new_variable = copy(self)
  let new_variable.attributes = a:attrs
  let new_variable.parent = {}
  return new_variable
endfunction


" Renders data of the variable
function! s:VarChild.render()
  let output = get(self.attributes, "name", "undefined") . "\t" . get(self.attributes, "type", "undefined") . "\t" . get(self.attributes, "value", "undefined")
  return output
endfunction



