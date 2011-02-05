class Collector

  def initialize(input, output)
    @path = File.dirname(__FILE__)
    @input_files = input.map{|i| @path + '/' + i}
    @output_file = File.expand_path(@path + '/' + output)
    @file = ''
  end
  
  def accumulate!
    read_file
    save_file
  end

  
  protected
  
    def read_file
      @file = ""
      plan = @input_files.inject([]) {|sum, i| sum += File.read(i).split("\n") }
      plan.each do |line|
        @file += File.read(@path + '/' + line)
        @file += "\n"
      end
      @file
    end
    
    
    def save_file
      File.open(@output_file, 'w') do |file|
        file.write(@file)
      end
    end
  
end


plugin = Collector.new(['ruby_debugger_plugin_plan.txt'], '../plugin/ruby_debugger.vim')
plugin.accumulate!

auto_load = Collector.new(['ruby_debugger_autoload_plan.txt'], '../autoload/ruby_debugger.vim')
auto_load.accumulate!

with_tests = Collector.new(['ruby_debugger_autoload_plan.txt', 'ruby_test_plan.txt'], 'additionals/autoload/ruby_debugger.vim')
with_tests.accumulate!
