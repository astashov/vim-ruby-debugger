" *** Breakpoint class (start)

let s:Breakpoint = { 'id': 0 }

" ** Public methods

" Constructor of new brekpoint. Create new breakpoint and set sign.
function! s:Breakpoint.new(file, line)
  let var = copy(self)
  let var.file = a:file
  let var.line = a:line
  let s:Breakpoint.id += 1
  let var.id = s:Breakpoint.id

  call var._set_sign()
  call var._log("Set breakpoint to: " . var.file . ":" . var.line)
  return var
endfunction


" Destroyer of the breakpoint. It just sends commands to debugger and destroys
" sign, but you should manually remove it from breakpoints array
function! s:Breakpoint.delete() dict
  call self._unset_sign()
  call self._send_delete_to_debugger()
endfunction


" Add condition to breakpoint. If server is not running, just store it, it
" will be evaluated after starting the server
function! s:Breakpoint.add_condition(condition) dict
  let self.condition = a:condition
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running() && has_key(self, 'debugger_id')
    call g:RubyDebugger.queue.add(self.condition_command())
  endif
endfunction



" Send adding breakpoint message to debugger, if it is run
function! s:Breakpoint.send_to_debugger() dict
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running()
    call g:RubyDebugger.queue.add(self.command())
  endif
endfunction


" Command for setting breakpoint (e.g.: 'break /path/to/file:23')
function! s:Breakpoint.command() dict
  return 'break ' . self.file . ':' . self.line
endfunction


" Command for adding condition to breakpoin (e.g.: 'condition 1 x>5')
function! s:Breakpoint.condition_command() dict
  return 'condition ' . self.debugger_id . ' ' . self.condition
endfunction


" Find and return breakpoint under cursor
function! s:Breakpoint.get_selected() dict
  let line = getline(".") 
  let match = matchlist(line, '^\(\d\+\)') 
  let id = get(match, 1)
  let breakpoints = filter(copy(g:RubyDebugger.breakpoints), "v:val.id == " . id)
  if !empty(breakpoints)
    return breakpoints[0]
  else
    return {}
  endif
endfunction


" Output format for Breakpoints Window
function! s:Breakpoint.render() dict
  let output = self.id . " " . (exists("self.debugger_id") ? self.debugger_id : '') . " " . self.file . ":" . self.line
  if exists("self.condition")
    let output .= " " . self.condition
  endif
  return output . "\n"
endfunction


" Open breakpoint in existed/new window
function! s:Breakpoint.open() dict
  call s:jump_to_file(self.file, self.line)
endfunction


" ** Private methods


function! s:Breakpoint._set_sign() dict
  if has("signs")
    exe ":sign place " . self.id . " line=" . self.line . " name=breakpoint file=" . self.file
  endif
endfunction


function! s:Breakpoint._unset_sign() dict
  if has("signs")
    exe ":sign unplace " . self.id
  endif
endfunction


function! s:Breakpoint._log(string) dict
  call g:RubyDebugger.logger.put(a:string)
endfunction


" Send deleting breakpoint message to debugger, if it is run
" (e.g.: 'delete 5')
function! s:Breakpoint._send_delete_to_debugger() dict
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running()
    let message = 'delete ' . self.debugger_id
    call g:RubyDebugger.queue.add(message)
  endif
endfunction


" *** Breakpoint class (end)
