" *** Server class (start)

let s:Server = {}

" ** Public methods

" Constructor of new server. Just inits it, not runs
function! s:Server.new(hostname, rdebug_port, debugger_port, runtime_dir, tmp_file, output_file) dict
  let var = copy(self)
  let var.hostname = a:hostname
  let var.rdebug_port = a:rdebug_port
  let var.runtime_dir = a:runtime_dir
  let var.output_file = a:output_file
  return var
endfunction


" Start the server. It will kill any listeners on given ports before.
function! s:Server.start(script) dict
  call self._stop_server(self.rdebug_port)
  " Remove leading and trailing quotes
  let script_name = substitute(a:script, "\\(^['\"]\\|['\"]$\\)", '', 'g')
  let rdebug = 'rdebug-ide -p ' . self.rdebug_port . ' -- ' . script_name

  " Start in background
  if has("win32") || has("win64")
    silent exe '! start ' . rdebug
    let debugger = 'ruby "' . expand(self.runtime_dir . "/bin/ruby_debugger.rb") . '"' . debugger_parameters
    silent exe '! start ' . debugger
  else
    call system(rdebug . ' > ' . self.output_file . ' 2>&1 &')
    call self.start_debugger(self.hostname, self.rdebug_port)
  endif

  " Set PIDs of processes
  let self.rdebug_pid = self._get_pid(self.rdebug_port, 1)
  call g:RubyDebugger.logger.put("Start debugger")
endfunction  


" Kill servers and empty PIDs
function! s:Server.stop() dict
  call self._kill_process(self.rdebug_pid)
  let self.rdebug_pid = ""
endfunction


function! s:Server.start_debugger(hostname, rdebug_port) dict
ruby << RUBY

require 'socket'

host = VIM.evaluate('a:hostname')
port = VIM.evaluate('a:rdebug_port')
@server_name = VIM.evaluate('v:servername')
@progname = VIM.evaluate('g:ruby_debugger_progname')
@tmp_file = VIM.evaluate('s:tmp_file')
@separator = VIM.evaluate('s:separator')

def wait_for_opened_socket(host, port)
  attempts = 0
  begin
    TCPSocket.open(host, port)
  rescue Errno::ECONNREFUSED => msg
    attempts += 1
    # If socket wasn't be opened for 20 seconds, exit
    if attempts < 400
      sleep 0.05
      retry
    else
      raise Errno::ECONNREFUSED, "#{host}:#{port} wasn't be opened"
    end
  end
end
@rdebug_ide = wait_for_opened_socket(host, port)

@forked_pid = Process.fork do

  Signal.trap("TERM") { exit }

  def read_rdebug_socket(response, rdebug, output = "")
    if response && response[0] && response[0][0]
      output += response[0][0].recv(10000)
      if have_unclosed_tag?(output)
        # If rdebug-ide doesn't send full message, we should wait for rest parts too.
        # We can understand that this is just part of message by matching unclosed tags
        another_response = select([rdebug], nil, nil)
      else
        # Sometimes by some reason rdebug-ide sends blank strings just after main message. 
        # We need to remove these strings by receiving them 
        another_response = select([rdebug], nil, nil, 0.01)
      end
      if another_response && another_response[0] && another_response[0][0]
        output = read_rdebug_socket(another_response, rdebug, output)
      end
    end
    output
  end

  def have_unclosed_tag?(output)
    start_match = output.match(/^<([a-zA-Z0-9\-_]+)>/)
    if start_match
      end_match = output.match(/<\/#{start_match[1]}>$/)
      return end_match ? false : true
    else
      return false
    end
  end

  loop do
    response = select([@rdebug_ide], nil, nil)
    result = []
    result << read_rdebug_socket(response, @rdebug_ide)
    # If we stop at breakpoint, add taking of local variables into queue
    stop_commands = [ '<breakpoint ', '<suspended ', '<exception ' ]
    if stop_commands.any? { |c| result.first.include?(c) }
      @rdebug_ide.puts("var local")
      response = select([@rdebug_ide], nil, nil)
      result << read_rdebug_socket(response, @rdebug_ide)
      @rdebug_ide.puts("where")
      response = select([@rdebug_ide], nil, nil)
      result << read_rdebug_socket(response, @rdebug_ide)
    end
    message = result.join(@separator)
    if message && !message.empty?
      File.open(@tmp_file, 'w') { |f| f.puts(message) }
      command = ":call RubyDebugger.receive_command()"
      starter = "<C-\\\\>"
      system("#{@progname} --servername #{@server_name} -u NONE -U NONE --remote-send \"#{starter}<C-N>#{command}<CR>\"")
    end
  end
end

RUBY

autocmd VimLeavePre * :call StopForkedRubyProcess()

endfunction

function! StopForkedRubyProcess()
ruby << RUBY
Process.kill("TERM", @forked_pid) if @forked_pid
RUBY
endfunction


" Return 1 if processes with set PID exist.
function! s:Server.is_running() dict
  return (self._get_pid(self.rdebug_port, 0) =~ '^\d\+$')
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


