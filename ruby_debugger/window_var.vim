" Inherits VarParent from VarChild
let s:WindowVariables = copy(s:Window)

function! s:WindowVariables.bind_mappings()
  nnoremap <buffer> <2-leftmouse> :call <SID>window_variables_activate_node()<cr>
  nnoremap <buffer> o :call <SID>window_variables_activate_node()<cr>"
endfunction


" TODO: Is there some way to call s:WindowVariables.activate_node from mapping
" command?
function! s:window_variables_activate_node()
  let variable = s:Var.get_selected()
  if variable != {} && variable.type == "VarParent"
    if variable.is_open
      call variable.close()
    else
      call variable.open()
    endif
  endif
endfunction



