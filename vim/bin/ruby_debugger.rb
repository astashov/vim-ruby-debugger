require 'socket'
require 'cgi'

def create_directory(file)
  dir = File.dirname(file)
  Dir.mkdir(dir) unless File.exist?(dir) && File.directory?(dir)
  dir
end

def read_socket(response, debugger)
  output = ""
  if response && response[0] && response[0][0]
    output = response[0][0].recv(10000)
    another_response = select([debugger], nil, nil, 0.01)
    if another_response && another_response[0] && another_response[0][0]
      output += read_socket(another_response, debugger)
    end
  end
  output
end

server = TCPServer.new('localhost', ARGV[1])
debugger = TCPSocket.open('localhost', ARGV[0])
create_directory(ARGV[4])

t1 = Thread.new do
  while(session = server.accept)
    input = session.gets
    break if input.chop == 'stop'
    debugger.puts(input)
  end
end
t2 = Thread.new do
  loop do 
    response = select([debugger], nil, nil)
    # Recursively read socket with interval 0.01 seconds. If there will no message in next 0.01 seconds, stop read.
    # This is need for reading whole message, because sometimes select/recv reads not all available data
    output = read_socket(response, debugger)
    output.gsub!(/&quot;/, "\"")
    File.open(ARGV[4], 'w') { |f| f.puts(output) }
    command = ":call RubyDebugger.receive_command()"
    system("#{ARGV[2]} --servername #{ARGV[3]} -u NONE -U NONE --remote-send \"<C-\\\\><C-N>#{command}<CR>\"");
 end
end

t1.join

debugger.puts('exit')
debugger.close
server.close
puts "End"
