" *** Creating instances (start)

" Initialize RUbyDebugger settings
if !exists("g:ruby_debugger_fast_sender")
  let g:ruby_debugger_fast_sender = 0
endif
if !exists("g:ruby_debugger_spec_path")
  let g:ruby_debugger_spec_path = '/usr/bin/spec'
endif
if !exists("g:ruby_debugger_cucumber_path")
  let g:ruby_debugger_cucumber_path = '/usr/bin/cucumber'
endif
if !exists("g:ruby_debugger_progname")
  let g:ruby_debugger_progname = v:progname
endif

" Creating windows
let s:variables_window = s:WindowVariables.new("variables", "Variables_Window")
let s:breakpoints_window = s:WindowBreakpoints.new("breakpoints", "Breakpoints_Window")
let s:frames_window = s:WindowFrames.new("frames", "Backtrace_Window")

" Init logger. The plugin logs all its actions. If you have some troubles,
" this file can help
let s:logger_file = s:runtime_dir . '/tmp/ruby_debugger_log'
let RubyDebugger.logger = s:Logger.new(s:logger_file)
let s:variables_window.logger = RubyDebugger.logger
let s:breakpoints_window.logger = RubyDebugger.logger
let s:frames_window.logger = RubyDebugger.logger


" *** Creating instances (end)


