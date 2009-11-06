" *** WindowBreakpoints class (start)

" Inherits WindowBreakpoints from Window
let s:WindowBreakpoints = copy(s:Window)

" ** Public methods

function! s:WindowBreakpoints.bind_mappings()
  nnoremap <buffer> <2-leftmouse> :call <SID>window_breakpoints_activate_node()<cr>
  nnoremap <buffer> o :call <SID>window_breakpoints_activate_node()<cr>
  nnoremap <buffer> d :call <SID>window_breakpoints_delete_node()<cr>
endfunction


" Returns string that contains all breakpoints (for Window.display())
function! s:WindowBreakpoints.render() dict
  let breakpoints = ""
  let breakpoints .= self.title . "\n"
  for breakpoint in g:RubyDebugger.breakpoints
    let breakpoints .= breakpoint.render()
  endfor
  let exceptions = map(copy(g:RubyDebugger.exceptions), 'v:val.render()')
  let breakpoints .= "\nException breakpoints: " . join(exceptions, ", ")
  return breakpoints
endfunction


" TODO: Is there some way to call s:WindowBreakpoints.activate_node from mapping
" command?
" Open breakpoint under cursor
function! s:window_breakpoints_activate_node()
  let breakpoint = s:Breakpoint.get_selected()
  if breakpoint != {}
    call breakpoint.open()
  endif
endfunction


" Delete breakpoint under cursor
function! s:window_breakpoints_delete_node()
  let breakpoint = s:Breakpoint.get_selected()
  if breakpoint != {}
    call breakpoint.delete()
    call filter(g:RubyDebugger.breakpoints, "v:val.id != " . breakpoint.id)
    call s:breakpoints_window.open()
  endif
endfunction


" Add syntax highlighting
function! s:WindowBreakpoints.setup_syntax_highlighting() dict
    execute "syn match rdebugTitle #" . self.title . "#"

    syn match rdebugId "^\d\+\s" contained nextgroup=rdebugDebuggerId
    syn match rdebugDebuggerId "\d*\s" contained nextgroup=rdebugFile
    syn match rdebugFile ".*:" contained nextgroup=rdebugLine
    syn match rdebugLine "\d\+" contained

    syn match rdebugWrapper "^\d\+.*" contains=rdebugId transparent

    hi def link rdebugId Directory
    hi def link rdebugDebuggerId Type
    hi def link rdebugFile Normal
    hi def link rdebugLine Special
endfunction


" *** WindowBreakpoints class (end)


