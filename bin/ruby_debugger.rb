require 'benchmark'
require 'socket'

class VimRubyDebugger

  def initialize(params)
    @params = params
    create_directory(@params[:messages_file])
    @rdebug = wait_for_opened_socket(@params[:host], @params[:rdebug_port])
    log("Start TCPServer with host: #{@params[:host]} and port: #{@params[:vim_ruby_debugger_port]}")
    @vim_ruby_debugger = TCPServer.new(@params[:host], @params[:vim_ruby_debugger_port])
    @queue = []
    @result = []
    @separator = "++vim-ruby-debugger separator++"
    run
  rescue => error
    log("ERROR!!!: #{error}\nBacktrace: #{error.backtrace}")
  end

  private

    def wait_for_opened_socket(host, port)
      attempts = 0
      begin
        log("Starting to connect by TCPSocket with host: #{host} and port: #{port}")
        socket = TCPSocket.open(host, port)
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
      log("Connected with #{host}:#{port} by TCPSocket by #{attempts} repeats")
      socket
    end


    def create_directory(file)
      dir = File.dirname(file)
      Dir.mkdir(dir) unless File.exist?(dir) && File.directory?(dir)
    end


    def run
      t1 = Thread.new do
        log("Start listening vim-ruby-debugger plugin")
        while(session = @vim_ruby_debugger.accept)
          input = session.gets
          log("Received data from vim-ruby-debugger: #{input}")
          @queue = input.split(@separator)
          handle_queue
        end
      end
      t2 = Thread.new do
        log("Start listening rdebug-ide")
        loop do 
          response = select([@rdebug], nil, nil)
          output = read_socket(response, @rdebug)
          log("Received data from rdebug-ide: #{output}")
          @result << truncate_variables_values(output)
          # If we stop at breakpoint, add taking of local variables into queue
          stop_commands = [ '<breakpoint ', '<suspended ', '<exception ' ]
          if stop_commands.any? { |c| output.include?(c) }
            @queue << "var local" 
            @queue << "where"
          end
          handle_queue
        end
      end

      t1.join

      @rdebug.puts('exit')
    ensure
      @rdebug.close if @rdebug
      @vim_ruby_debugger.close if @vim_ruby_debugger
    end


    def read_socket(response, debugger, output = "")
      if response && response[0] && response[0][0]
        output += response[0][0].recv(10000)
        if have_unclosed_tag?(output)
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


    def handle_queue
      unless @queue.empty?
        log("Queue is not empty, we will pass queue to rdebug-ide")
        message = @queue.shift
        log("Putting message to rdebug-ide: #{message}")
        @rdebug.puts(message)
        # Start command doesn't return any response, so send message immediatly
        send_message if message.strip == 'start'
      else
        send_message
      end
    end


    def send_message
      message = @result.join(@separator)
      log("Sending message to vim-ruby-debugger: #{message}")
      @result = []
      if message && !message.empty?
        log("Put message to temp file")
        File.open(@params[:messages_file], 'w') { |f| f.puts(message) }
        command = ":call RubyDebugger.receive_command()"
        starter = (@params[:os] == 'win' ? "<C-\\>" : "<C-\\\\>")
        sys_cmd = "#{@params[:vim_executable]} --servername #{@params[:vim_servername]} -u NONE -U NONE --remote-send \"#{starter}<C-N>#{command}<CR>\""
        log("Executing command: #{sys_cmd}")
        system(sys_cmd);
      end
    end


    def truncate_variables_values(message)
      if message.size > 30000 && message.include?("<variables>")
        previous_position = 0
        while(start_position = message.index('value="', previous_position))
          start_position += 6
          end_position = message.index('"', start_position + 1)
          length = end_position - start_position
          if length > 30000
            value = message[(start_position + 1)..(start_position + 30000)]
            value += " (the variable is truncated, its full length is #{length})"
          else
            value = message[(start_position + 1)..(end_position - 1)]
          end
          message = message[0..start_position] + value + message[end_position..-1]
          previous_position = start_position
        end
        message
      else
        message
      end
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


    def log(string)
      if @params[:debug_mode] == '1'
        File.open(@params[:logger_file], 'a') do |f|
          # match vim redir style new lines, rather than trailing
          f << "\nRuby_debugger.rb, #{Time.now.strftime("%H:%M:%S")} : #{string.chomp}"
        end
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
  :os => ARGV[6],
  :debug_mode => ARGV[7],
  :logger_file => ARGV[8]
)
