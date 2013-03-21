" *** Creating instances (start)

if !exists("g:ruby_debugger_debug_mode")
  let g:ruby_debugger_debug_mode = 0
endif
if !exists("g:ruby_debugger_executable")
  let g:ruby_debugger_executable = "rdebug-vim"
endif
if !exists("g:ruby_debugger_spec_path")
  let g:ruby_debugger_spec_path = 'rspec'
endif
if !exists("g:ruby_debugger_cucumber_path")
  let g:ruby_debugger_cucumber_path = 'cucumber'
endif
if !exists("g:ruby_debugger_progname")
  let g:ruby_debugger_progname = v:progname
endif
if !exists("g:ruby_debugger_default_script")
  let g:ruby_debugger_default_script = 'script/rails server'
endif
if !exists("g:ruby_debugger_no_maps")
  let g:ruby_debugger_no_maps = 0
endif

" Creating windows
let s:variables_window = s:WindowVariables.new("variables", "Variables_Window")
let s:breakpoints_window = s:WindowBreakpoints.new("breakpoints", "Breakpoints_Window")
let s:frames_window = s:WindowFrames.new("frames", "Backtrace_Window")

" Init logger. The plugin logs all its actions. If you have some troubles,
" this file can help
let RubyDebugger.logger = s:Logger.new(s:logger_file)
let s:variables_window.logger = RubyDebugger.logger
let s:breakpoints_window.logger = RubyDebugger.logger
let s:frames_window.logger = RubyDebugger.logger

autocmd VimLeavePre * :call RubyDebugger.stop()

" *** Creating instances (end)
