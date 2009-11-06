" *** Exception class (start)
" These are ruby exceptions we catch with 'catch Exception' command
" (:RdbCatch)

let s:Exception = { }

" ** Public methods

" Constructor of new exception.
function! s:Exception.new(name)
  let var = copy(self)
  let var.name = a:name
  call var._log("Trying to set exception: " . var.name)
  call g:RubyDebugger.queue.add(var.command())
  return var
endfunction


" Command for setting exception (e.g.: 'catch NameError')
function! s:Exception.command() dict
  return 'catch ' . self.name
endfunction


" Output format for Breakpoints Window
function! s:Exception.render() dict
  return self.name
endfunction


" ** Private methods


function! s:Exception._log(string) dict
  call g:RubyDebugger.logger.put(a:string)
endfunction


" *** Exception class (end)



