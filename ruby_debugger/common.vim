function! s:get_tags(cmd)
  let tags = []
  let cmd = a:cmd
  let inner_tags_match = s:get_inner_tags(cmd)
  if !empty(inner_tags_match)
    let pattern = '<.\{-}\/>' 
    let inner_tags = inner_tags_match[1]
    let tagmatch = matchlist(inner_tags, pattern)
    while empty(tagmatch) == 0
      call add(tags, tagmatch[0])
      let tagmatch[0] = escape(tagmatch[0], '[]~*\')
      let inner_tags = substitute(inner_tags, tagmatch[0], '', '')
      let tagmatch = matchlist(inner_tags, pattern)
    endwhile
  endif
  return tags
endfunction


function! s:get_inner_tags(cmd)
  return matchlist(a:cmd, '^<.\{-}>\(.\{-}\)<\/.\{-}>$')
endfunction 


function! s:get_tag_attributes(cmd)
  let attributes = {}
  let cmd = a:cmd
  " Find type of used quotes (" or ')
  let quote_match = matchlist(cmd, "\\w\\+=\\(.\\)")
  let quote = empty(quote_match) ? "\"" : escape(quote_match[1], "'\"")
  let pattern = "\\(\\w\\+\\)=" . quote . "\\(.\\{-}\\)" . quote
  let attrmatch = matchlist(cmd, pattern) 
  while !empty(attrmatch)
    let attributes[attrmatch[1]] = s:unescape_html(attrmatch[2])
    let attrmatch[0] = escape(attrmatch[0], '[]~*\')
    let cmd = substitute(cmd, attrmatch[0], '', '')
    let attrmatch = matchlist(cmd, pattern) 
  endwhile
  return attributes
endfunction


function! s:unescape_html(html)
  let result = substitute(a:html, "&amp;", "\\&", "")
  let result = substitute(result, "&quot;", "\"", "")
  let result = substitute(result, "&lt;", "<", "")
  let result = substitute(result, "&gt;", ">", "")
  return result
endfunction


function! s:get_filename()
  return expand("%:p")
endfunction


function! s:send_message_to_debugger(message)
  call system("ruby -e \"require 'socket'; a = TCPSocket.open('localhost', 39768); a.puts('" . a:message . "'); a.close\"")
endfunction


function! s:unplace_signs()
  if has("signs")
    exe ":sign unplace " . s:current_line_sign_id
  endif
endfunction


function! s:clear_current_state()
  call s:unplace_signs()
  let g:RubyDebugger.variables = {}
  if s:variables_window.is_open()
    call s:variables_window.open()
  endif
endfunction



function! s:jump_to_file(file, line)
  " If no buffer with this file has been loaded, create new one
  if !bufexists(bufname(a:file))
     exe ":e! " . a:file
  endif

  let window_number = bufwinnr(bufnr(a:file))
  if window_number != -1
     exe window_number . "wincmd w"
  endif

  " open buffer of a:file
  if bufname(a:file) != bufname("%")
     exe ":buffer " . bufnr(a:file)
  endif

  " jump to line
  exe ":" . a:line
  normal z.
  if foldlevel(a:line) != 0
     normal zo
  endif

  return bufname(a:file)

endfunction


function! s:is_window_usable(winnumber)
    "gotta split if there is only one window
    if winnr("$") ==# 1
        return 0
    endif

    let oldwinnr = winnr()
    exe a:winnumber . "wincmd p"
    let specialWindow = getbufvar("%", '&buftype') != '' || getwinvar('%', '&previewwindow')
    let modified = &modified
    exe oldwinnr . "wincmd p"

    "if it is a special window, e.g. quickfix or another explorer plugin, then we
    " have to split
    if specialWindow
      return 0
    endif

    if &hidden
      return 1
    endif

    return !modified || s:buf_in_windows(winbufnr(a:winnumber)) >= 2
endfunction


function! s:buf_in_windows(bnum)
    let cnt = 0
    let winnum = 1
    while 1
        let bufnum = winbufnr(winnum)
        if bufnum < 0
            break
        endif
        if bufnum ==# a:bnum
            let cnt = cnt + 1
        endif
        let winnum = winnum + 1
    endwhile

    return cnt
endfunction 


function! s:first_normal_window()
    let i = 1
    while i <= winnr("$")
        let bnum = winbufnr(i)
        if bnum != -1 && getbufvar(bnum, '&buftype') ==# ''
                    \ && !getwinvar(i, '&previewwindow')
            return i
        endif

        let i += 1
    endwhile
    return -1
endfunction
