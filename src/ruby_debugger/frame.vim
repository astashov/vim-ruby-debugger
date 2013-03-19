" *** Frame class (start)

let s:Frame = { }

" ** Public methods

" Constructor of new frame.
" Create new frame and set sign to it.
function! s:Frame.new(attrs)
  let var = copy(self)
  let var.no = a:attrs.no
  let var.file = a:attrs.file
  let var.line = a:attrs.line
  if has_key(a:attrs, 'current')
    let var.current = (a:attrs.current == 'true')
  else
    let var.current = 0
  endif
  "let s:sign_id += 1
  "let var.sign_id = s:sign_id
  "call var._set_sign()
  return var
endfunction


" Find and return frame under cursor
function! s:Frame.get_selected() dict
  let line = getline(".")
  let match = matchlist(line, '^\(\d\+\)')
  let no = get(match, 1)
  let frames = filter(copy(g:RubyDebugger.frames), "v:val.no == " . no)
  if !empty(frames)
    return frames[0]
  else
    return {}
  endif
endfunction


" Output format for Frame Window
function! s:Frame.render() dict
  return self.no . (self.current ? ' Current' : ''). " " . self.file . ":" . self.line . "\n"
endfunction


" Open frame in existed/new window
function! s:Frame.open() dict
  call s:jump_to_file(self.file, self.line)
endfunction


" ** Private methods

function! s:Frame._set_sign() dict
  if has("signs")
    exe ":sign place " . self.sign_id . " line=" . self.line . " name=frame file=" . self.file
  endif
endfunction


function! s:Frame._unset_sign() dict
  if has("signs")
    exe ":sign unplace " . self.sign_id
  endif
endfunction


" *** Frame class (end)


