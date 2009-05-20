" Init section - set mappings, default values, highlight colors

map <Leader>b  :call g:RubyDebugger.toggle_breakpoint()<CR>
map <Leader>v  :call g:RubyDebugger.open_variables()<CR>
map <Leader>m  :call g:RubyDebugger.open_breakpoints()<CR>
map <Leader>s  :call g:RubyDebugger.step()<CR>
map <Leader>n  :call g:RubyDebugger.next()<CR>
map <Leader>c  :call g:RubyDebugger.continue()<CR>
map <Leader>e  :call g:RubyDebugger.exit()<CR>

command! -nargs=? -complete=file Rdebugger :call g:RubyDebugger.start(<q-args>) 
command! -nargs=1 RdbCommand :call g:RubyDebugger.send_command(<q-args>) 

if exists("g:loaded_ruby_debugger")
  finish
endif
if v:version < 700
  echoerr "RubyDebugger: This plugin requires Vim >= 7."
  finish
endif
if !has("clientserver")
  echoerr "RubyDebugger: This plugin requires +clientserver option"
  finish
endif
let g:loaded_ruby_debugger = 1


let s:rdebug_port = 39767
let s:debugger_port = 39768
" ~/.vim for Linux, vimfiles for Windows
let s:runtime_dir = split(&runtimepath, ',')[0]
" File for communicating between intermediate Ruby script ruby_debugger.rb and
" this plugin
let s:tmp_file = s:runtime_dir . '/tmp/ruby_debugger'
let s:server_output_file = s:runtime_dir . '/tmp/ruby_debugger_output'
" Default id for sign of current line
let s:current_line_sign_id = 120

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

