" Init section - set mappings, default values, highlight colors

map <Leader>b  :call g:RubyDebugger.toggle_breakpoint()<CR>
map <Leader>v  :call g:RubyDebugger.open_variables()<CR>
map <Leader>m  :call g:RubyDebugger.open_breakpoints()<CR>
map <Leader>t  :call g:RubyDebugger.open_frames()<CR>
map <Leader>s  :call g:RubyDebugger.step()<CR>
map <Leader>f  :call g:RubyDebugger.finish()<CR>
map <Leader>n  :call g:RubyDebugger.next()<CR>
map <Leader>c  :call g:RubyDebugger.continue()<CR>
map <Leader>e  :call g:RubyDebugger.exit()<CR>
map <Leader>d  :call g:RubyDebugger.remove_breakpoints()<CR>

command! -nargs=? -complete=file Rdebugger :call g:RubyDebugger.start(<q-args>) 
command! -nargs=0 RdbStop :call g:RubyDebugger.stop() 
command! -nargs=1 RdbCommand :call g:RubyDebugger.send_command(<q-args>) 
command! -nargs=0 RdbTest :call g:RubyDebugger.run_test() 
command! -nargs=1 RdbEval :call g:RubyDebugger.eval(<q-args>)
command! -nargs=1 RdbCond :call g:RubyDebugger.conditional_breakpoint(<q-args>)
command! -nargs=1 RdbCatch :call g:RubyDebugger.catch_exception(<q-args>)

if exists("g:ruby_debugger_loaded")
  "finish
endif
if v:version < 700 
  echoerr "RubyDebugger: This plugin requires Vim >= 7."
  finish
endif
if !has("clientserver")
  echoerr "RubyDebugger: This plugin requires +clientserver option"
  finish
endif
if !executable("rdebug-ide")
  echoerr "RubyDebugger: You don't have installed 'ruby-debug-ide' gem or executable 'rdebug-ide' can't be found in your PATH"
  finish
endif
if !(has("win32") || has("win64")) && !executable("lsof")
  echoerr "RubyDebugger: You don't have 'lsof' installed or executable 'lsof' can't be found in your PATH"
  finish
endif
let g:ruby_debugger_loaded = 1


let s:rdebug_port = 39767
let s:debugger_port = 39768
" hostname() returns something strange in Windows (E98BD9A419BB41D), so set hostname explicitly
let s:hostname = 'localhost' "hostname()
" ~/.vim for Linux, vimfiles for Windows
let s:runtime_dir = split(&runtimepath, ',')[0]
" File for communicating between intermediate Ruby script ruby_debugger.rb and
" this plugin
let s:tmp_file = s:runtime_dir . '/tmp/ruby_debugger'
let s:server_output_file = s:runtime_dir . '/tmp/ruby_debugger_output'
" Default id for sign of current line
let s:current_line_sign_id = 120
let s:separator = "++vim-ruby-debugger separator++"
let s:sign_id = 0

" Create tmp directory if it doesn't exist
if !isdirectory(s:runtime_dir . '/tmp')
  call mkdir(s:runtime_dir . '/tmp')
endif


" Init breakpoing signs
hi def link Breakpoint Error
sign define breakpoint linehl=Breakpoint  text=xx

" Init current line signs
hi def link CurrentLine DiffAdd 
sign define current_line linehl=CurrentLine text=>>


" End of init section

