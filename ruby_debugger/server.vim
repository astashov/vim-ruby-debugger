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
  return var
endfunction


" Start the server. It will kill any listeners on given ports before.
function! s:Server.start(script) dict
  call self._stop_server(self.rdebug_port)
  call self._stop_server(self.debugger_port)
  " Remove leading and trailing quotes
  let script_name = substitute(a:script, "\\(^['\"]\\|['\"]$\\)", '', 'g')
  let rdebug = 'rdebug-ide -p ' . self.rdebug_port . ' -- ' . script_name
  let os = has("win32") || has("win64") ? 'win' : 'posix'
  " Example - ruby ~/.vim/bin/ruby_debugger.rb 39767 39768 vim VIM /home/anton/.vim/tmp/ruby_debugger posix
  let debugger_parameters = ' ' . self.hostname . ' ' . self.rdebug_port . ' ' . self.debugger_port . ' ' . g:ruby_debugger_progname . ' ' . v:servername . ' "' . self.tmp_file . '" ' . os

  " Start in background
  if has("win32") || has("win64")
    silent exe '! start ' . rdebug
    let debugger = 'ruby "' . expand(self.runtime_dir . "/bin/ruby_debugger.rb") . '"' . debugger_parameters
    silent exe '! start ' . debugger
  else
    call system(rdebug . ' > ' . self.output_file . ' 2>&1 &')
    let debugger = 'ruby ' . expand(self.runtime_dir . "/bin/ruby_debugger.rb") . debugger_parameters
    call system(debugger. ' &')
  endif

  " Set PIDs of processes
  let self.rdebug_pid = self._get_pid(self.rdebug_port, 1)
  let self.debugger_pid = self._get_pid(self.debugger_port, 1)

  call g:RubyDebugger.logger.put("Start debugger")
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
" parameter is true, it will try to get PID for 20 seconds.
function! s:Server._get_pid(port, must_get_pid)
  let attempt = 0
  let pid = self._get_pid_attempt(a:port)
  while a:must_get_pid && pid == "" && attempt < 2000
    sleep 10m
    let attempt += 1
    let pid = self._get_pid_attempt(a:port)
  endwhile
  return pid
endfunction


" Just try to get PID of process and return empty string if it was
" unsuccessful
function! s:Server._get_pid_attempt(port)
  if has("win32") || has("win64")
    let netstat = system("netstat -anop tcp")
    let pid_match = matchlist(netstat, ':' . a:port . '\s.\{-}LISTENING\s\+\(\d\+\)')
    let pid = len(pid_match) > 0 ? pid_match[1] : ""
  elseif executable('lsof')
    let pid = system("lsof -i tcp:" . a:port . " | grep LISTEN | awk '{print $2}'")
    let pid = substitute(pid, '\n', '', '')
  else
    let pid = ""
  endif
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
  echo "Killing server with pid " . a:pid
  call system("ruby -e 'Process.kill(9," . a:pid . ")'")
  sleep 100m
  call self._log("Killed server with pid: " . a:pid)
endfunction


function! s:Server._log(string) dict
  call g:RubyDebugger.logger.put(a:string)
endfunction


" *** Server class (end)


