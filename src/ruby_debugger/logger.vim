" *** Logger class (start)

let s:Logger = {} 

function! s:Logger.new(file)
  let new_variable = copy(self)
  let new_variable.file = a:file
  call writefile([], new_variable.file)
  return new_variable
endfunction


" Log datetime and then message. It logs only if debug mode is enabled
" TODO It outputs a bunch of spaces at the front of the entry - fix that.
function! s:Logger.put(string) dict
  if g:ruby_debugger_debug_mode
    let string = 'Vim plugin, ' . strftime("%H:%M:%S") . ': ' . a:string
    execute('set verbosefile=' . g:RubyDebugger.logger.file)
    silent verbose echo substitute(string,'/^\s*/','',"") 
    execute('set verbosefile=""')
  endif
endfunction

" *** Logger class (end)
