require 'socket'

def create_directory(file)
  dir = File.dirname(file)
  Dir.mkdir(dir) unless File.exist?(dir) && File.directory?(dir)
  dir
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

server = TCPServer.new('localhost', ARGV[1])
debugger = TCPSocket.open('localhost', ARGV[0])
create_directory(ARGV[4])

storage = []


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
    File.open(ARGV[4], 'w') { |f| f.puts(output) }
    command = ":call RubyDebugger.receive_command()"
    starter = (ARGV[5] == 'win' ? "<C-\\>" : "<C-\\\\>")
    system("#{ARGV[2]} --servername #{ARGV[3]} -u NONE -U NONE --remote-send \"" + starter + "<C-N>#{command}<CR>\"");
 end
end

t1.join

debugger.puts('exit')
debugger.close
server.close
puts "End"
