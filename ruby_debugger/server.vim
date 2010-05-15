" *** Server class (start)

let s:Server = {}

" ** Public methods

" Constructor of new server. Just inits it, not runs
function! s:Server.new(host, port, output_file, tmp_file, servername, progname, separator) dict
  let var = copy(self)
  let var.host = a:host
  let var.port = a:port
  let var.output_file = a:output_file
  let var.tmp_file = a:tmp_file
  let var.servername = a:servername
  let var.progname = a:progname
  let var.separator = a:separator
  return var
endfunction


" Start the server. It will kill any listeners on given ports before.
function! s:Server.start(script) dict
  if self._check_already_running_server(self.port)
    echo "Another Vim instance has running rdebug-ide. Please stop it there (or kill 'zombie' rdebug-ide process if there is no running VIM)"
    return 0
  endif
  call self._stop_server()
  " Remove leading and trailing quotes
  let script_name = substitute(a:script, "\\(^['\"]\\|['\"]$\\)", '', 'g')
  let rdebug_ide = 'rdebug-ide -p ' . self.port . ' -- ' . script_name

  " Start in background
  if has("win32") || has("win64")
    "silent exe '! start ' . rdebug
    "let debugger = 'ruby "' . expand(self.runtime_dir . "/bin/ruby_debugger.rb") . '"' . debugger_parameters
    "silent exe '! start ' . debugger
  else
    call system(rdebug_ide . ' > ' . self.output_file . ' 2>&1 &')
    call self.start_debugger(self.host, self.port, self.tmp_file, self.servername, self.progname, self.separator)
  endif
  autocmd VimLeavePre * :call g:RubyDebugger.stop()

  " Set PIDs of processes
  let self.rdebug_pid = self._get_pid(self.port, 1)
  call g:RubyDebugger.logger.put("Start debugger")
endfunction  


" Kill servers and empty PIDs
function! s:Server.stop() dict
  call self._stop_server()
  let self.rdebug_pid = ""
endfunction


function! s:Server.start_debugger(host, port, tmp_file, servername, progname, separator) dict
ruby << RUBY

  require 'socket'
  host = VIM.evaluate('a:host')
  port = VIM.evaluate('a:port')
  @tmp_file = VIM.evaluate('a:tmp_file')
  @server_name = VIM.evaluate('a:servername')
  @progname = VIM.evaluate('a:progname')
  @separator = VIM.evaluate('a:separator')

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
endfunction


" Return 1 if processes with set PID exist.
function! s:Server.is_running() dict
  return (self._get_pid(self.port, 0) =~ '^\d\+$')
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


function! s:Server._check_already_running_server(port)
  let pid = self._get_pid(a:port, 0)
ruby << RUBY
  if VIM.evaluate('l:pid').to_i != 0 && !@rdebug_ide
    VIM.command('let result = 1')
  else
    VIM.command('let result = 0')
  end
RUBY
  return result
endfunction


" Kill listener of given host/port
function! s:Server._stop_server() dict
ruby << RUBY
  if @forked_pid
    Process.kill("TERM", @forked_pid)
    VIM.command("echo 'Forked process is stopped'")
    @forked_pid = nil
  end
  if @rdebug_ide
    @rdebug_ide.puts("exit")
    @rdebug_ide.flush
    @rdebug_ide.close
    VIM.command("echo 'Rdebug-ide is stopped'")
    @rdebug_ide = nil
  end
RUBY
endfunction


" Kill listener of given host/port
function! s:Server._kill_server(port) dict
  let pid = self._get_pid(a:port, 0)
  if pid =~ '^\d\+$'
    call self._kill_process(pid)
  endif
endfunction


" Kill process with given PID
function! s:Server._kill_process(pid) dict
  echo "Killing server with pid " . a:pid
  ruby "Process.kill('KILL', VIM.evaluate('a:pid'))"
  sleep 100m
  call self._log("Killed server with pid: " . a:pid)
endfunction


function! s:Server._log(string) dict
  call g:RubyDebugger.logger.put(a:string)
endfunction


" *** Server class (end)


