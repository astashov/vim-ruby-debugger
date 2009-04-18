" Vim plugin for debugging Rails applications
" Maintainer: Anton Astashov (anton at astashov dot net, http://astashov.net)

map <Leader>b  :call RubyDebugger.set_breakpoint()<CR>
map <Leader>r  :call RubyDebugger.receive_command()<CR>
map <Leader>v  :call RubyDebugger.variables.toggle()<CR>
command! Rdebugger :call RubyDebugger.start() 

" if exists("g:loaded_ruby_debugger")
"     finish
" endif
" if v:version < 700
"     echoerr "RubyDebugger: This plugin requires Vim >= 7."
"     finish
" endif
" let g:loaded_ruby_debugger = 1

let RubyDebugger = { 'commands': {}, 'variables': {}, 'settings': {} }

let s:rdebug_port = 39767
let s:debugger_port = 39768
let s:runtime_dir = split(&runtimepath, ',')[0]
let s:tmp_file = s:runtime_dir . '/tmp/ruby_debugger'

let s:variables_buf_name = "Variables_Window"
let s:next_buffer_number = 1

let RubyDebugger.settings.variables_win_position = 'botright'
let RubyDebugger.settings.variables_win_size = 10


" Init breakpoing signs
hi breakpoint  term=NONE    cterm=NONE    gui=NONE
sign define breakpoint  linehl=breakpoint  text=>>
