if (exists("b:did_ftplugin"))
  finish
endif
let b:did_ftplugin = 1

let s:cpo_save = &cpo
set cpo&vim

if !exists("g:ruby_debugger_no_maps") || !g:ruby_debugger_no_maps
  noremap <buffer> <leader>b  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.toggle_breakpoint()<CR>
  noremap <buffer> <leader>v  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_variables()<CR>
  noremap <buffer> <leader>m  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_breakpoints()<CR>
  noremap <buffer> <leader>t  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_frames()<CR>
  noremap <buffer> <leader>s  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.step()<CR>
  noremap <buffer> <leader>f  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.finish()<CR>
  noremap <buffer> <leader>n  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.next()<CR>
  noremap <buffer> <leader>c  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.continue()<CR>
  noremap <buffer> <leader>e  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.exit()<CR>
  noremap <buffer> <leader>d  :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.remove_breakpoints()<CR>
endif

command! -buffer -nargs=* -complete=file Rdebugger call ruby_debugger#load_debugger() | call g:RubyDebugger.start(<q-args>) 
command! -buffer -nargs=0 RdbStop call g:RubyDebugger.stop() 
command! -buffer -nargs=1 RdbCommand call g:RubyDebugger.send_command_wrapper(<q-args>) 
command! -buffer -nargs=0 RdbTest call g:RubyDebugger.run_test() 
command! -buffer -nargs=0 RdbTestSingle call g:RubyDebugger.run_test(" -l " . line("."))
command! -buffer -nargs=1 RdbEval call g:RubyDebugger.eval(<q-args>)
command! -buffer -nargs=1 RdbCond call g:RubyDebugger.conditional_breakpoint(<q-args>)
command! -buffer -nargs=1 RdbCatch call g:RubyDebugger.catch_exception(<q-args>)
command! -buffer -nargs=0 RdbLog call ruby_debugger#load_debugger() | call g:RubyDebugger.show_log()

let &cpo = s:cpo_save
unlet s:cpo_save
