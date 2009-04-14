require 'socket'

server = TCPServer.new('localhost', ARGV[1])
debugger = TCPSocket.open('localhost', ARGV[0])
debugger.puts('start')

t1 = Thread.new do
  while(session = server.accept)
    input = session.gets
    break if input.chop == 'stop'
    debugger.puts(input)
  end
end
t2 = Thread.new do
  loop do 
    response = select([debugger], nil, nil, 10)
      if response && response[0] && response[0][0]
      output = response[0][0].recv(10000)
      File.open(ARGV[2], 'w') { |f| f.print(output) }
    end
  end
end

t1.join

debugger.puts('exit')
debugger.close
server.close
puts "End"
