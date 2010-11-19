if exists("g:ruby_debugger_loaded")
  finish
endif

map <leader>b  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.toggle_breakpoint()<CR>
map <leader>v  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_variables()<CR>
map <leader>m  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_breakpoints()<CR>
map <leader>t  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_frames()<CR>
map <leader>s  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.step()<CR>
map <leader>f  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.finish()<CR>
map <leader>n  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.next()<CR>
map <leader>c  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.continue()<CR>
map <leader>e  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.exit()<CR>
map <leader>d  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.remove_breakpoints()<CR>

command! -nargs=? -complete=file Rdebugger call ruby_debugger#load_debugger() | call g:RubyDebugger.start(<q-args>) 
command! -nargs=0 RdbStop call g:RubyDebugger.stop() 
command! -nargs=1 RdbCommand call g:RubyDebugger.send_command_wrapper(<q-args>) 
command! -nargs=0 RdbTest call g:RubyDebugger.run_test() 
command! -nargs=1 RdbEval call g:RubyDebugger.eval(<q-args>)
command! -nargs=1 RdbCond call g:RubyDebugger.conditional_breakpoint(<q-args>)
command! -nargs=1 RdbCatch call g:RubyDebugger.catch_exception(<q-args>)
command! -nargs=0 RdbLog call ruby_debugger#load_debugger() | call g:RubyDebugger.show_log()

let g:ruby_debugger_loaded = 1


