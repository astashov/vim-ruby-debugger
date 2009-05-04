" *** Abstract Class for creating window. Should be inherited. ***

let s:Window = {} 
let s:Window['next_buffer_number'] = 1 
let s:Window['position'] = 'botright'
let s:Window['size'] = 10


function! s:Window.new(name, title) dict
  let new_variable = copy(self)
  let new_variable.name = a:name
  let new_variable.title = a:title
  return new_variable
endfunction


function! s:Window.clear() dict
  silent 1,$delete _
endfunction


function! s:Window.close() dict
  if !self.is_open()
    throw "RubyDebug: Window " . self.name . " is not open"
  endif

  if winnr("$") != 1
    call self.focus()
    close
    exe "wincmd p"
  else
    :q
  endif
  call self._log("Closed window with name: " . self.name)
endfunction


function! s:Window.get_number() dict
  if self._exist_for_tab()
    return bufwinnr(self._buf_name())
  else
    return -1
  endif
endfunction


function! s:Window.display()
  call self._log("Start displaying data in window with name: " . self.name)
  call self.focus()
  setlocal modifiable

  let current_line = line(".")
  let current_column = col(".")
  let top_line = line("w0")

  call self.clear()

  call setline(top_line, self.title)
  call cursor(top_line + 1, current_column)

  call self._insert_data()
  call self._restore_view(top_line, current_line, current_column)

  setlocal nomodifiable
  call self._log("Complete displaying data in window with name: " . self.name)
endfunction


function! s:Window.focus() dict
  exe self.get_number() . " wincmd w"
  call self._log("Set focus to window with name: " . self.name)
endfunction


function! s:Window.is_open() dict
    return self.get_number() != -1
endfunction


function! s:Window.open() dict
    if !self.is_open()
      " create the window
      silent exec self.position . ' ' . self.size . ' new'

      if !self._exist_for_tab()
        call self._set_buf_name(self._next_buffer_name())
        silent! exec "edit " . self._buf_name()
        " This function does not exist in Window class and should be declared in
        " childrens
        call self.bind_mappings()
      else
        silent! exec "buffer " . self._buf_name()
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
      setfiletype ruby_debugger_window
      call self._log("Opened window with name: " . self.name)
    endif

    if has("syntax") && exists("g:syntax_on") && !has("syntax_items")
      call self.setup_syntax_highlighting()
    endif

    call self.display()
endfunction


function! s:Window.toggle() dict
  call self._log("Toggling window with name: " . self.name)
  if self._exist_for_tab() && self.is_open()
    call self.close()
  else
    call self.open()
  end
endfunction


function! s:Window._buf_name() dict
  return t:window_{self.name}_buf_name
endfunction


function! s:Window._exist_for_tab() dict
  return exists("t:window_" . self.name . "_buf_name") 
endfunction


function! s:Window._insert_data() dict
  let old_p = @p
  let @p = self.render()
  silent put p
  let @p = old_p
  call self._log("Inserted data to window with name: " . self.name)
endfunction


function! s:Window._log(string) dict
  if has_key(self, 'logger')
    call self.logger.put(a:string)
  endif
endfunction


function! s:Window._next_buffer_name() dict
  let name = self.name . s:Window.next_buffer_number
  let s:Window.next_buffer_number += 1
  return name
endfunction


function! s:Window._restore_view(top_line, current_line, current_column) dict
 "restore the view
  let old_scrolloff=&scrolloff
  let &scrolloff=0
  call cursor(a:top_line, 1)
  normal! zt
  call cursor(a:current_line, a:current_column)
  let &scrolloff = old_scrolloff 
  call self._log("Restored view of window with name: " . self.name)
endfunction


function! s:Window._set_buf_name(name) dict
  let t:window_{self.name}_buf_name = a:name
endfunction








