" *** Logger class (start)


let s:Logger = {} 

function! s:Logger.new(file)
  let new_variable = copy(self)
  let new_variable.file = a:file
  call writefile([], new_variable.file)
  return new_variable
endfunction


" Log datetime and then message
function! s:Logger.put(string)
  let file = readfile(self.file)
  let string = 'Vim plugin, ' . strftime("%H:%M:%S") . ': ' . a:string
  call add(file, string)
  call writefile(file, self.file)
endfunction


" Log only if debug mode is enabled
function! s:Logger.debug(string)
  if g:ruby_debugger_debug_mode
    call self.put(a:string)
  endif
endfunction


" *** Logger class (end)

