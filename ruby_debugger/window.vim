" *** Window class (start). Abstract Class for creating window. 
"     Must be inherited. Mostly, stolen from the NERDTree.

let s:Window = {} 
let s:Window['next_buffer_number'] = 1 
let s:Window['position'] = 'botright'
let s:Window['size'] = 10

" ** Public methods

" Constructs new window
function! s:Window.new(name, title) dict
  let new_variable = copy(self)
  let new_variable.name = a:name
  let new_variable.title = a:title
  return new_variable
endfunction


" Clear all data from window
function! s:Window.clear() dict
  silent 1,$delete _
endfunction


" Close window
function! s:Window.close() dict
  if !self.is_open()
    throw "RubyDebug: Window " . self.name . " is not open"
  endif

  if winnr("$") != 1
    call self.focus()
    close
    exe "wincmd p"
  else
    " If this is only one window, just quit
    :q
  endif
  call self._log("Closed window with name: " . self.name)
endfunction


" Get window number
function! s:Window.get_number() dict
  if self._exist_for_tab()
    return bufwinnr(self._buf_name())
  else
    return -1
  endif
endfunction


" Display data to the window
function! s:Window.display()
  call self._log("Start displaying data in window with name: " . self.name)
  call self.focus()
  setlocal modifiable

  let current_line = line(".")
  let current_column = col(".")
  let top_line = line("w0")

  call self.clear()

  call self._insert_data()
  call self._restore_view(top_line, current_line, current_column)

  setlocal nomodifiable
  call self._log("Complete displaying data in window with name: " . self.name)
endfunction


" Put cursor to the window
function! s:Window.focus() dict
  exe self.get_number() . " wincmd w"
  call self._log("Set focus to window with name: " . self.name)
endfunction


" Return 1 if window is opened
function! s:Window.is_open() dict
    return self.get_number() != -1
endfunction


" Open window and display data (stolen from NERDTree)
function! s:Window.open() dict
    if !self.is_open()
      " create the window
      silent exec self.position . ' ' . self.size . ' new'

      if !self._exist_for_tab()
        " If the window is not opened/exists, create new
        call self._set_buf_name(self._next_buffer_name())
        silent! exec "edit " . self._buf_name()
        " This function does not exist in Window class and should be declared in
        " descendants
        call self.bind_mappings()
      else
        " Or just jump to opened buffer
        silent! exec "buffer " . self._buf_name()
      endif

      " set buffer options
      setlocal winfixheight
      setlocal noswapfile
      setlocal buftype=nofile
      setlocal nowrap
      setlocal foldcolumn=0
      setlocal nobuflisted
      setlocal nospell
      setlocal nolist
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


" Open/close window
function! s:Window.toggle() dict
  call self._log("Toggling window with name: " . self.name)
  if self._exist_for_tab() && self.is_open()
    call self.close()
  else
    call self.open()
  end
endfunction


" ** Private methods


" Return buffer name, that is stored in tab variable
function! s:Window._buf_name() dict
  return t:window_{self.name}_buf_name
endfunction


" Return 1 if the window exists in current tab
function! s:Window._exist_for_tab() dict
  return exists("t:window_" . self.name . "_buf_name") 
endfunction


" Insert data to the window
function! s:Window._insert_data() dict
  let old_p = @p
  " Put data to the register and then show it by 'put' command
  let @p = self.render()
  silent exe "normal \"pP"
  let @p = old_p
  call self._log("Inserted data to window with name: " . self.name)
endfunction


function! s:Window._log(string) dict
  if has_key(self, 'logger')
    call self.logger.put(a:string)
  endif
endfunction


" Calculate correct name for the window
function! s:Window._next_buffer_name() dict
  let name = self.name . s:Window.next_buffer_number
  let s:Window.next_buffer_number += 1
  return name
endfunction


" Restore the view
function! s:Window._restore_view(top_line, current_line, current_column) dict
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


" *** Window class (end)


