" *** Server class (start)

let s:Server = {}

" ** Public methods

" Constructor of new server. Just inits it, not runs
function! s:Server.new() dict
  let var = copy(self)
  call s:log("Initializing Server object")
  return var
endfunction


" Start the server. It will kill any listeners on given ports before.
function! s:Server.start(script, params) dict
  call self.stop()
  call s:log("Starting Server, command: " . a:script)
  " Remove leading and trailing quotes
  let script_name = substitute(a:script, "\\(^['\"]\\|['\"]$\\)", '', 'g')
  let s:socket_file = tempname()
  let cmd = g:ruby_debugger_executable . ' --file ' . s:tmp_file . ' --output ' . s:server_output_file . ' --socket ' . s:socket_file . ' --logger_file ' . s:logger_file .  ' --debug_mode ' . g:ruby_debugger_debug_mode .  ' --vim_executable ' . g:ruby_debugger_progname .  ' --vim_servername ' . v:servername . ' --separator ' . s:separator . ' -- ' . script_name
  call s:log("Executing command: ". cmd)
  let s:rdebug_pid = split(system(cmd), "\n")[-1]
  call s:log("PID: " . s:rdebug_pid)
  call s:log("Waiting for starting debugger...")
endfunction


" Kill servers and empty PIDs
function! s:Server.stop() dict
ruby << RUBY
  if @vim_ruby_debugger_socket
    @vim_ruby_debugger_socket.close
    @vim_ruby_debugger_socket = nil
  end
RUBY
  call s:log("Stopping, pid is: " . s:rdebug_pid)
  if s:rdebug_pid =~ '^\d\+$'
    call self._kill_process(s:rdebug_pid)
  endif
  let s:rdebug_pid = ""
endfunction


" Return 1 if processes with set PID exist.
function! s:Server.is_running() dict
  return !empty(s:rdebug_pid)
endfunction


" Kill process with given PID
function! s:Server._kill_process(pid) dict
  let message = "Killing server with pid " . a:pid
  call s:log(message)
  echo message
  let cmd = "ruby -e 'Process.kill(9," . a:pid . ")'"
  call s:log("Executing command: " . cmd)
  call system(cmd)
  call s:log("Killed server with pid: " . a:pid)
endfunction


" *** Server class (end)


