map <Leader>b  :call g:RubyDebugger.toggle_breakpoint()<CR>
map <Leader>v  :call g:RubyDebugger.open_variables()<CR>
map <Leader>m  :call g:RubyDebugger.open_breakpoints()<CR>
map <Leader>s  :call g:RubyDebugger.step()<CR>
map <Leader>n  :call g:RubyDebugger.next()<CR>
map <Leader>c  :call g:RubyDebugger.continue()<CR>
map <Leader>e  :call g:RubyDebugger.exit()<CR>

command! Rdebugger :call g:RubyDebugger.start() 

" if exists("g:loaded_ruby_debugger")
"     finish
" endif
" if v:version < 700
"     echoerr "RubyDebugger: This plugin requires Vim >= 7."
"     finish
" endif
" let g:loaded_ruby_debugger = 1

let s:rdebug_port = 39767
let s:debugger_port = 39768
let s:runtime_dir = split(&runtimepath, ',')[0]
let s:tmp_file = s:runtime_dir . '/tmp/ruby_debugger'

if &t_Co < '16'
  let s:breakpoint_ctermbg = 1
else
  let s:breakpoint_ctermbg = 4
endif

" Init breakpoing signs
exe "hi Breakpoint term=NONE ctermbg=" . s:breakpoint_ctermbg . " guifg=#E6E1DC guibg=#7E1111"
sign define breakpoint linehl=Breakpoint  text=xx

" Init current line signs
hi CurrentLine term=NONE ctermbg=2 guifg=#E6E1DC guibg=#144212 term=NONE
sign define current_line linehl=CurrentLine text=>>
