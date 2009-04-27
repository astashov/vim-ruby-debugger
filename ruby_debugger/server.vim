let s:Server = {}

function! s:Server.new(rdebug_port, debugger_port, runtime_dir, tmp_file) dict
  let var = copy(self)
  let var.rdebug_port = a:rdebug_port
  let var.debugger_port = a:debugger_port
  let var.runtime_dir = a:runtime_dir
  let var.tmp_file = a:tmp_file
  return var
endfunction


function! s:Server.start() dict
  call self._stop_server('localhost', s:rdebug_port)
  call self._stop_server('localhost', s:debugger_port)
  let rdebug = 'rdebug-ide -p ' . self.rdebug_port . ' -- script/server &'
  let debugger = 'ruby ' . expand(self.runtime_dir . "/bin/ruby_debugger.rb") . ' ' . self.rdebug_port . ' ' . self.debugger_port . ' ' . v:progname . ' ' . v:servername . ' "' . self.tmp_file . '" &'
  call system(rdebug)
  exe 'sleep 2'
  call system(debugger)

  let self.rdebug_pid = self._get_pid('localhost', self.rdebug_port)
  let self.debugger_pid = self._get_pid('localhost', self.debugger_port)

  call g:RubyDebugger.logger.put("Start debugger")
endfunction  


function! s:Server.stop() dict
  call self._kill_process(self.rdebug_pid)
  call self._kill_process(self.debugger_pid)
  let self.rdebug_pid = ""
  let self.debugger_pid = ""
endfunction


function! s:Server.is_running() dict
  return (self._get_pid('localhost', self.rdebug_port) =~ '^\d\+$') && (self._get_pid('localhost', self.debugger_port) =~ '^\d\+$')
endfunction


function! s:Server._get_pid(bind, port)
  if has("win32") || has("win64")
    let netstat = system("netstat -anop tcp")
    let pid = matchstr(netstat, '\<' . a:bind . ':' . a:port . '\>.\{-\}LISTENING\s\+\zs\d\+')
  elseif executable('lsof')
    let pid = system("lsof -i 4tcp@" . a:bind . ':' . a:port . " | grep LISTEN | awk '{print $2}'")
    let pid = substitute(pid, '\n', '', '')
  else
    let pid = ""
  endif
  return pid
endfunction


function! s:Server._stop_server(bind, port) dict
  let pid = self._get_pid(a:bind, a:port)
  if pid =~ '^\d\+$'
    call self._kill_process(pid)
  endif
endfunction


function! s:Server._kill_process(pid) dict
  echo "Killing server with pid " . a:pid
  call system("ruby -e 'Process.kill(9," . a:pid . ")'")
  sleep 100m
  call self._log("Killed server with pid: " . a:pid)
endfunction


function! s:Server._log(string) dict
  call g:RubyDebugger.logger.put(a:string)
endfunction




