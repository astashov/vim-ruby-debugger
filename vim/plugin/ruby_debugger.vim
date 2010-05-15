if exists("g:ruby_debugger_loaded")
  finish
endif

noremap <leader>b  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.toggle_breakpoint()<CR>
noremap <leader>v  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_variables()<CR>
noremap <leader>m  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_breakpoints()<CR>
noremap <leader>t  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_frames()<CR>
noremap <leader>s  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.command('step'.(v:count > 1 ? ' '.v:count : ''))<CR>
noremap <leader>f  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.finish()<CR>
noremap <leader>n  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.command('next'.(v:count > 1 ? ' '.v:count : ''))<CR>
noremap <leader>c  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.continue()<CR>
noremap <leader>e  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.exit()<CR>
noremap <leader>d  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.remove_breakpoints()<CR>

command! -nargs=? -complete=file Rdebugger call ruby_debugger#load_debugger() | call g:RubyDebugger.start(<q-args>) 
command! -nargs=0 RdbStop call ruby_debugger#load_debugger() | call g:RubyDebugger.stop() 
command! -nargs=1 RdbCommand call ruby_debugger#load_debugger() | call g:RubyDebugger.send_command(<q-args>) 
command! -nargs=0 RdbTest call ruby_debugger#load_debugger() | call g:RubyDebugger.run_test() 
command! -nargs=1 RdbEval call ruby_debugger#load_debugger() | call g:RubyDebugger.eval(<q-args>)
command! -nargs=1 RdbCond call ruby_debugger#load_debugger() | call g:RubyDebugger.conditional_breakpoint(<q-args>)
command! -nargs=1 RdbCatch call ruby_debugger#load_debugger() | call g:RubyDebugger.catch_exception(<q-args>)

let g:ruby_debugger_loaded = 1


