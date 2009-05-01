let s:variables_window = s:WindowVariables.new("variables", "Variables_Window", g:RubyDebugger.variables)
let s:breakpoints_window = s:WindowBreakpoints.new("breakpoints", "Breakpoints_Window", g:RubyDebugger.breakpoints)

let RubyDebugger.logger = s:Logger.new(s:runtime_dir . '/tmp/ruby_debugger_log')
let s:variables_window.logger = RubyDebugger.logger
let s:breakpoints_window.logger = RubyDebugger.logger
