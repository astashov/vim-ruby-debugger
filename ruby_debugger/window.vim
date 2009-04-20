" *** Variables window ***

function! RubyDebugger.variables.toggle() dict
  if s:variables_exist_for_tab()
    if !s:is_variables_open()
      call self.create_window()
    else
      call self.close_window()
    endif
  else
    call self.init()
  end
endfunction


function! s:variables_exist_for_tab()
  return exists("t:variables_buf_name") 
endfunction


function! s:is_variables_open()
    return s:get_variables_win_num() != -1
endfunction


function! s:get_variables_win_num()
  if s:variables_exist_for_tab()
    return bufwinnr(t:variables_buf_name)
  else
    return -1
  endif
endfunction


function! s:next_buffer_name()
  let name = s:variables_buf_name . s:next_buffer_number
  let s:next_buffer_number += 1
  return name
endfunction


function! RubyDebugger.variables.init() dict
  if s:variables_exist_for_tab()
    if s:is_variables_open()
      call self.close_window()
    endif
    unlet t:variables_buf_name
  endif
  call self.create_window()
endfunction


function! RubyDebugger.variables.create_window() dict
    " create the variables tree window
    let splitLocation = g:RubyDebugger.settings.variables_win_position
    let splitSize = g:RubyDebugger.settings.variables_win_size
    silent exec splitLocation . ' ' . splitSize . ' new'

    if !exists('t:variables_buf_name')
      let t:variables_buf_name = s:next_buffer_name()
      silent! exec "edit " . t:variables_buf_name
    else
      silent! exec "buffer " . t:variables_buf_name
    endif

    " set buffer options
    setlocal winfixwidth
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal nowrap
    setlocal foldcolumn=0
    setlocal nobuflisted
    setlocal nospell
    iabc <buffer>
    setlocal cursorline
    setfiletype variablestree

    call s:bind_mappings()
    call g:RubyDebugger.variables.update()
endfunction


function! RubyDebugger.variables.close_window() dict
  if !s:is_variables_open()
    throw "No Variables Tree is open"
  endif

  if winnr("$") != 1
    exe s:get_variables_win_num() . " wincmd w"
    close
    exe "wincmd p"
  else
    :q
  endif
endfunction


function! RubyDebugger.variables.update() dict
  let g:RubyDebugger.variables.need_to_get = [ 'local' ]
  call s:collect_variables() 
endfunction


function! s:collect_variables()
  if !empty(g:RubyDebugger.variables.need_to_get)
    let type = remove(g:RubyDebugger.variables.need_to_get, 0)
    if type == 'local'
      call s:send_message_to_debugger('var local')
    end
  else
    call s:display_variables()
  endif
endfunction


function! s:display_variables()
  setlocal modifiable

  let current_line = line(".")
  let current_column = col(".")
  let top_line = line("w0")
  " delete all lines in the buffer (being careful not to clobber a register)
  silent 1,$delete _

  call setline(top_line, "Variables:")
  call cursor(top_line + 1, current_column)

  let old_p = @p
  let @p = g:RubyDebugger.variables.list.render()
  silent put p
  let @p = old_p

 "restore the view
  let old_scrolloff=&scrolloff
  let &scrolloff=0
  call cursor(top_line, 1)
  normal! zt
  call cursor(current_line, current_column)
  let &scrolloff = old_scrolloff 

  setlocal nomodifiable
endfunction


function! s:bind_mappings()
  nnoremap <silent> <buffer> <2-leftmouse> :call <SID>activate_node()<cr>
  nnoremap <silent> <buffer> o :call <SID>activate_node()<cr>"
endfunction


function! s:activate_node()
  let variable = s:Var.get_selected()
  if variable != {} && variable.type == "VarParent"
    if variable.is_open
      call variable.close()
    else
      call variable.open()
    endif
  endif
endfunction

" *** End of variables window ***



