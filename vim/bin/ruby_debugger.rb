require 'socket'

class VimRubyDebugger

  def initialize(params)
    @params = params
    create_directory(@params[:messages_file])
    @rdebug = wait_for_opened_socket(@params[:host], @params[:rdebug_port])
    @vim_ruby_debugger = TCPServer.new(@params[:host], @params[:vim_ruby_debugger_port])
    run
  end

  private

    def wait_for_opened_socket(host, port, &block)
      attempts = 0
      begin
        socket = TCPSocket.open(host, port)
        yield if block_given?
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
      socket
    end


    def create_directory(file)
      dir = File.dirname(file)
      Dir.mkdir(dir) unless File.exist?(dir) && File.directory?(dir)
    end


    def run
      t1 = Thread.new do
        while(session = @vim_ruby_debugger.accept)
          input = session.gets
          @rdebug.puts(input)
        end
      end
      t2 = Thread.new do
        loop do 
          response = select([@rdebug], nil, nil)
          output = read_socket(response, @rdebug)
          File.open(@params[:messages_file], 'w') { |f| f.puts(output) }
          command = ":call RubyDebugger.receive_command()"
          starter = (@params[:os] == 'win' ? "<C-\\>" : "<C-\\\\>")
          system("#{@params[:vim_executable]} --servername #{@params[:vim_servername]} -u NONE -U NONE --remote-send \"" + starter + "<C-N>#{command}<CR>\"");
        end
      end

      t1.join

      @rdebug.puts('exit')
      @rdebug.close
      @vim_ruby_debugger.close
    end


    def read_socket(response, debugger, output = "")
      if response && response[0] && response[0][0]
        output += response[0][0].recv(10000)
        if have_unclosed_tag(output)
          # If rdebug-ide doesn't send full message, we should wait for rest parts too.
          # We can understand that this is just part of message by matching unclosed tags
          another_response = select([debugger], nil, nil)
        else
          # Sometimes by some reason rdebug-ide sends blank strings just after main message. 
          # We need to remove these strings by receiving them 
          another_response = select([debugger], nil, nil, 0.01)
        end
        if another_response && another_response[0] && another_response[0][0]
          output = read_socket(another_response, debugger, output)
        end
      end
      output
    end


    def have_unclosed_tag(output)
      start_match = output.match(/^<([a-zA-Z0-9\-_]+)>/)
      if start_match
        end_match = output.match(/<\/#{start_match[1]}>$/)
        return end_match ? false : true
      else
        return false
      end
    end

end


VimRubyDebugger.new(
  :host => ARGV[0],
  :rdebug_port => ARGV[1],
  :vim_ruby_debugger_port => ARGV[2],
  :vim_executable => ARGV[3],
  :vim_servername => ARGV[4],
  :messages_file => ARGV[5],
  :os => ARGV[6]
)
