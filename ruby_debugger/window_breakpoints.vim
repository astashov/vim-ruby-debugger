let s:WindowBreakpoints = copy(s:Window)

function! s:WindowBreakpoints.bind_mappings()
  nnoremap <buffer> <2-leftmouse> :call <SID>window_breakpoints_activate_node()<cr>
  nnoremap <buffer> o :call <SID>window_breakpoints_activate_node()<cr>
  nnoremap <buffer> d :call <SID>window_breakpoints_delete_node()<cr>
endfunction


function! s:WindowBreakpoints.render() dict
  let breakpoints = ""
  for breakpoint in g:RubyDebugger.breakpoints
    let breakpoints .= breakpoint.render()
  endfor
  return breakpoints
endfunction


" TODO: Is there some way to call s:WindowBreakpoints.activate_node from mapping
" command?
function! s:window_breakpoints_activate_node()

endfunction


function! s:window_breakpoints_delete_node()
  let breakpoint = s:Breakpoint.get_selected()
  if breakpoint != {}
    call breakpoint.delete()
    call filter(g:RubyDebugger.breakpoints, "v:val.id != " . breakpoint.id)
    call s:breakpoints_window.open()
  endif
endfunction



