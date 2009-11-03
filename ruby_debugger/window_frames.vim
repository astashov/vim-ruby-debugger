" *** WindowFrames class (start)

" Inherits WindowFrames from Window
let s:WindowFrames = copy(s:Window)

" ** Public methods

function! s:WindowFrames.bind_mappings()
  nnoremap <buffer> <2-leftmouse> :call <SID>window_frames_activate_node()<cr>
  nnoremap <buffer> o :call <SID>window_frames_activate_node()<cr>
endfunction


" Returns string that contains all frames (for Window.display())
function! s:WindowFrames.render() dict
  let frames = ""
  let frames .= self.title . "\n"
  for frame in g:RubyDebugger.frames
    let frames .= frame.render()
  endfor
  return frames
endfunction


" Open frame under cursor
function! s:window_frames_activate_node()
  let frame = s:Frame.get_selected()
  if frame != {}
    call frame.open()
  endif
endfunction


" Add syntax highlighting
function! s:WindowFrames.setup_syntax_highlighting() dict
    execute "syn match rdebugTitle #" . self.title . "#"

    syn match rdebugId "^\d\+\s" contained nextgroup=rdebugFile
    syn match rdebugFile ".*:" contained nextgroup=rdebugLine
    syn match rdebugLine "\d\+" contained

    syn match rdebugWrapper "^\d\+.*" contains=rdebugId transparent

    hi def link rdebugId Directory
    hi def link rdebugFile Normal
    hi def link rdebugLine Special
endfunction


" *** WindowFrames class (end)



