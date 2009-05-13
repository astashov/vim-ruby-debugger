let s:Breakpoint = { 'id': 0 }

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


function! s:Breakpoint.delete() dict
  call self._unset_sign()
  call self._send_delete_to_debugger()
endfunction


function! s:Breakpoint.send_to_debugger() dict
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running()
    let message = 'break ' . self.file . ':' . self.line
    call g:RubyDebugger.send_command(message)
  endif
endfunction


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


function! s:Breakpoint._log(string) dict
  call g:RubyDebugger.logger.put(a:string)
endfunction


function! s:Breakpoint._send_delete_to_debugger() dict
  if has_key(g:RubyDebugger, 'server') && g:RubyDebugger.server.is_running()
    let message = 'delete ' . self.debugger_id
    call g:RubyDebugger.send_command(message)
  endif
endfunction


function! s:Breakpoint.render() dict
  return self.id . " " . (exists("self.debugger_id") ? self.debugger_id : '') . " " . self.file . ":" . self.line . "\n"
endfunction


function! s:Breakpoint.open() dict
  call s:jump_to_file(self.file, self.line)
endfunction

