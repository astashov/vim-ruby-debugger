" Set g:ruby_debugger_create_default_mappings to 0 if you wish not to create any
" key mappings (useful if you wish to do them yourself).
if !exists('g:ruby_debugger_create_default_mappings')
    let g:ruby_debugger_create_default_mappings = 1
endif

if exists("g:ruby_debugger_loaded")
  finish
endif

noremap <plug>ruby_debugger_breakpoint :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.toggle_breakpoint()<cr>
noremap <plug>ruby_debugger_open_variables :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_variables()<CR>
noremap <plug>ruby_debugger_open_breakpoints :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_breakpoints()<CR>
noremap <plug>ruby_debugger_open_frames :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.open_frames()<CR>
noremap <plug>ruby_debugger_step :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.step()<CR>
noremap <plug>ruby_debugger_finish :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.finish()<CR>
noremap <plug>ruby_debugger_next :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.next()<CR>
noremap <plug>ruby_debugger_continue :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.continue()<CR>
noremap <plug>ruby_debugger_exit :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.exit()<CR>
noremap <plug>ruby_debugger_remove_breakpoints :call ruby_debugger#load_debugger() <bar> call g:RubyDebugger.remove_breakpoints()<CR>

if g:ruby_debugger_create_default_mappings
    if (!hasmapto('<leader>b'))
        nmap <leader>b <plug>ruby_debugger_breakpoint
    endif
    if (!hasmapto('<leader>v'))
        nmap <leader>v <plug>ruby_debugger_open_variables
    endif
    if (!hasmapto('<leader>m'))
        nmap <leader>m <plug>ruby_debugger_open_breakpoints
    endif
    if (!hasmapto('<leader>t'))
        nmap <leader>t <plug>ruby_debugger_open_frames
    endif
    if (!hasmapto('<leader>s'))
        nmap <leader>s <plug>ruby_debugger_step
    endif
    if (!hasmapto('<leader>f'))
        nmap <leader>f <plug>ruby_debugger_finish
    endif
    if (!hasmapto('<leader>n'))
        nmap <leader>n <plug>ruby_debugger_next
    endif
    if (!hasmapto('<leader>c'))
        nmap <leader>c <plug>ruby_debugger_continue
    endif
    if (!hasmapto('<leader>e'))
        nmap <leader>e <plug>ruby_debugger_exit
    endif
    if (!hasmapto('<leader>d'))
        nmap <leader>d <plug>ruby_debugger_remove_breakpoints
    endif
endif

command! -nargs=* -complete=file Rdebugger call ruby_debugger#load_debugger() | call g:RubyDebugger.start(<q-args>) 
command! -nargs=0 RdbStop call g:RubyDebugger.stop() 
command! -nargs=1 RdbCommand call g:RubyDebugger.send_command_wrapper(<q-args>) 
command! -nargs=0 RdbTest call g:RubyDebugger.run_test() 
command! -nargs=1 RdbEval call g:RubyDebugger.eval(<q-args>)
command! -nargs=1 RdbCond call g:RubyDebugger.conditional_breakpoint(<q-args>)
command! -nargs=1 RdbCatch call g:RubyDebugger.catch_exception(<q-args>)
command! -nargs=0 RdbLog call ruby_debugger#load_debugger() | call g:RubyDebugger.show_log()

let g:ruby_debugger_loaded = 1


