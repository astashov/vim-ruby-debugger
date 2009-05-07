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
    match_opening_tag = output.match(/^<([^\/]+)>/)
    if match_opening_tag
      # Check that closing tag is presented. If this is false, there should be next message, wait for it.
      match_closing_tag = output.match(/<\/#{match_opening_tag[1]}>/)
      unless match_closing_tag
        another_response = select([debugger], nil, nil)
        output += read_socket(another_response, debugger)
      end
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
    debugger.puts(input)
  end
end
t2 = Thread.new do
  loop do 
    response = select([debugger], nil, nil)
    output = read_socket(response, debugger)
    next if output.strip.blank?
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
