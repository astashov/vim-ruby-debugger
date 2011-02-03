" *** Logger class (start)

let s:Logger = {} 

function! s:Logger.new(file)
  let new_variable = copy(self)
  let new_variable.file = a:file
  call writefile([], new_variable.file)
  return new_variable
endfunction


" Log datetime and then message. It logs only if debug mode is enabled
" TODO: Now to add one line to the log file, it read whole file to memory, add
" one line and write all that stuff back to file. When log file is large, it
" affects performance very much. Need to find way to write only to the end of
" file (preferably - crossplatform way. Maybe Ruby?)
function! s:Logger.put(string)
  if g:ruby_debugger_debug_mode
    let file = readfile(self.file)
    let string = 'Vim plugin, ' . strftime("%H:%M:%S") . ': ' . a:string
    call add(file, string)
    call writefile(file, self.file)
  endif
endfunction

" *** Logger class (end)


