" Init section - set default values, highlight colors

" It loads this file and inits global variables. 
" Required for autoloading the code for this plugin
fun! ruby_debugger#load_debugger()
  let s:rdebug_port = 39767
  let s:debugger_port = 39768
  " hostname() returns something strange in Windows (E98BD9A419BB41D), so set hostname explicitly
  let s:hostname = 'localhost' "hostname()
  " ~/.vim for Linux, vimfiles for Windows
  let s:runtime_dir = expand('<sfile>:h:h')
  " File for communicating between intermediate Ruby script ruby_debugger.rb and
  " this plugin
  let s:tmp_file = s:runtime_dir . '/tmp/ruby_debugger'
  let s:server_output_file = s:runtime_dir . '/tmp/ruby_debugger_output'
  " Default id for sign of current line
  let s:current_line_sign_id = 120
  let s:separator = "++vim-ruby-debugger separator++"
  let s:sign_id = 0

  if !s:check_prerequisites()
    finish
  endif

  " Create tmp directory if it doesn't exist
  if !isdirectory(s:runtime_dir . '/tmp')
    call mkdir(s:runtime_dir . '/tmp')
  endif

  " Init breakpoint signs
  hi def link Breakpoint Error
  sign define breakpoint linehl=Breakpoint  text=xx

  " Init current line signs
  hi def link CurrentLine DiffAdd 
  sign define current_line linehl=CurrentLine text=>>

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
endf


" Check all requirements for the current plugin
fun! s:check_prerequisites()
  let problems = []
  if v:version < 700 
    call add(problems, "RubyDebugger: This plugin requires Vim >= 7.")
  endif
  if !has("clientserver")
    call add(problems, "RubyDebugger: This plugin requires +clientserver option")
  endif
  if !executable("rdebug-ide")
    call add(problems, "RubyDebugger: You don't have installed 'ruby-debug-ide' gem or executable 'rdebug-ide' can't be found in your PATH")
  endif
  if !(has("win32") || has("win64")) && !executable("lsof")
    call add(problems, "RubyDebugger: You don't have 'lsof' installed or executable 'lsof' can't be found in your PATH")
  endif
  if empty(problems)
    return 1
  else
    for p in problems
      echoerr p
    endfor
    return 0
  endif
endf


" End of init section

