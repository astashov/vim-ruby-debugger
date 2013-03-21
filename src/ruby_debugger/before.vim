" Init section - set default values, highlight colors

" like ~/.vim
let s:runtime_dir = expand('<sfile>:h:h')
" File for communicating between intermediate Ruby script ruby_debugger.rb and
" this plugin
let s:tmp_file = s:runtime_dir . '/tmp/ruby_debugger'
let s:logger_file = s:runtime_dir . '/tmp/ruby_debugger_log'
let s:server_output_file = s:runtime_dir . '/tmp/ruby_debugger_output'
" Default id for sign of current line
let s:current_line_sign_id = 120
let s:separator = "++vim-ruby-debugger-separator++"
let s:sign_id = 0
let s:rdebug_pid = ""

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

" Loads this file. Required for autoloading the code for this plugin
fun! ruby_debugger#load_debugger()
  if !s:check_prerequisites()
    finish
  endif
endf

fun! ruby_debugger#statusline()
  let is_running = g:RubyDebugger.is_running()
  if is_running == 0
    return ''
  endif
  return '[ruby debugger running]'
endfunction

" Check all requirements for the current plugin
fun! s:check_prerequisites()
  let problems = []
  if v:version < 700
    call add(problems, "RubyDebugger: This plugin requires Vim >= 7.")
  endif
  if !has("clientserver")
    call add(problems, "RubyDebugger: This plugin requires +clientserver option")
  endif
  if !has("ruby")
    call add(problems, "RubyDebugger: This plugin requires +ruby option.")
  end
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

