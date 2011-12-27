" *** Server class (start)

let s:Server = {}

" ** Public methods

" Constructor of new server. Just inits it, not runs
function! s:Server.new(hostname, rdebug_port, debugger_port, runtime_dir, tmp_file, output_file) dict
  let var = copy(self)
  let var.hostname = a:hostname
  let var.rdebug_port = a:rdebug_port
  let var.debugger_port = a:debugger_port
  let var.runtime_dir = a:runtime_dir
  let var.tmp_file = a:tmp_file
  let var.output_file = a:output_file
  call s:log("Initializing Server object, with variables: hostname: " . var.hostname . ", rdebug_port: " . var.rdebug_port . ", debugger_port: " . var.debugger_port . ", runtime_dir: " . var.runtime_dir . ", tmp_file: " . var.tmp_file . ", output_file: " . var.output_file)
  return var
endfunction


" Start the server. It will kill any listeners on given ports before.
function! s:Server.start(script, params) dict
  call s:log("Starting Server, command: " . a:script)
  call s:log("Trying to kill all old servers first")
  call self._stop_server(self.rdebug_port)
  call self._stop_server(self.debugger_port)
  call s:log("Servers are killed, trying to start new servers")
  " Remove leading and trailing quotes
  let script_name = substitute(a:script, "\\(^['\"]\\|['\"]$\\)", '', 'g')
  let rdebug = 'rdebug-ide ' . join(a:params, ' ') . ' -p ' . self.rdebug_port . ' -- ' . script_name
  let os = has("win32") || has("win64") ? 'win' : 'posix'
  " Example - ruby ~/.vim/bin/ruby_debugger.rb 39767 39768 vim VIM /home/anton/.vim/tmp/ruby_debugger posix
  let debugger_parameters =  ' ' . self.hostname . ' ' . self.rdebug_port . ' ' . self.debugger_port
  let debugger_parameters .= ' ' . g:ruby_debugger_progname . ' ' . v:servername . ' "' . self.tmp_file
  let debugger_parameters .= '" ' . os . ' ' . g:ruby_debugger_debug_mode . ' ' . s:logger_file

  " Start in background
  if has("win32") || has("win64")
    silent exe '! start ' . rdebug
    let debugger = 'ruby "' . expand(self.runtime_dir . "/bin/ruby_debugger.rb") . '"' . debugger_parameters
    silent exe '! start ' . debugger
  else
    let cmd = rdebug . ' > ' . self.output_file . ' 2>&1 &'
    call s:log("Executing command: ". cmd)
    call system(cmd)
    let debugger_cmd = 'ruby ' . expand(self.runtime_dir . "/bin/ruby_debugger.rb") . debugger_parameters . ' &'
    call s:log("Executing command: ". debugger_cmd)
    call system(debugger_cmd)
  endif

  " Set PIDs of processes
  call s:log("Now we need to store PIDs of servers, retrieving them: ")
  let self.rdebug_pid = self._get_pid(self.rdebug_port, 1)
  let self.debugger_pid = self._get_pid(self.debugger_port, 1)
  call s:log("Server PIDs are: rdebug-ide: " . self.rdebug_pid . ", ruby_debugger.rb: " . self.debugger_pid)

  call s:log("Debugger is successfully started")
endfunction  


" Kill servers and empty PIDs
function! s:Server.stop() dict
  call self._kill_process(self.rdebug_pid)
  call self._kill_process(self.debugger_pid)
  let self.rdebug_pid = ""
  let self.debugger_pid = ""
endfunction


" Return 1 if processes with set PID exist.
function! s:Server.is_running() dict
  return (self._get_pid(self.rdebug_port, 0) =~ '^\d\+$') && (self._get_pid(self.debugger_port, 0) =~ '^\d\+$')
endfunction


" ** Private methods


" Get PID of process, that listens given port on given host. If must_get_pid
" parameter is true, it will try to get PID for 10 seconds.
function! s:Server._get_pid(port, must_get_pid)
  call s:log("Trying to find PID of process on " . a:port . " port, must_get_pid = " . a:must_get_pid)
  let attempt = 0
  let pid = self._get_pid_attempt(a:port)
  while a:must_get_pid && pid == "" && attempt < 1000
    sleep 10m
    let attempt += 1
    let pid = self._get_pid_attempt(a:port)
  endwhile
  call s:log("PID - " . pid . ", found by " . attempt . " repeats")
  return pid
endfunction


" Just try to get PID of process and return empty string if it was
" unsuccessful
function! s:Server._get_pid_attempt(port)
  call s:log("Trying to find listener of port " . a:port)
  if has("win32") || has("win64")
    let netstat = system("netstat -anop tcp")
    let pid_match = matchlist(netstat, ':' . a:port . '\s.\{-}LISTENING\s\+\(\d\+\)')
    let pid = len(pid_match) > 0 ? pid_match[1] : ""
  elseif executable('lsof')
    let cmd = "lsof -i tcp:" . a:port . " | grep LISTEN | awk '{print $2}'"
    call s:log("Executing command: " . cmd)
    let pid = system(cmd)
    let pid = substitute(pid, '\n', '', '')
  else
    let pid = ""
  endif
  call s:log("Found pid - " . pid)
  return pid
endfunction


" Kill listener of given host/port
function! s:Server._stop_server(port) dict
  let pid = self._get_pid(a:port, 0)
  if pid =~ '^\d\+$'
    call self._kill_process(pid)
  endif
endfunction


" Kill process with given PID
function! s:Server._kill_process(pid) dict
  let message = "Killing server with pid " . a:pid
  call s:log(message)
  echo message
  let cmd = "ruby -e 'Process.kill(9," . a:pid . ")'"
  call s:log("Executing command: " . cmd)
  call system(cmd)
  call s:log("Sleeping 100m...")
  sleep 100m
  call s:log("Killed server with pid: " . a:pid)
endfunction


" *** Server class (end)


