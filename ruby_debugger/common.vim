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
  let pattern = "\\(\\w\\+\\)=[\"']\\(.\\{-}\\)[\"']"
  let attrmatch = matchlist(cmd, pattern) 
  while empty(attrmatch) == 0
    let attributes[attrmatch[1]] = attrmatch[2]
    let cmd = substitute(cmd, attrmatch[0], '', '')
    let attrmatch = matchlist(cmd, pattern) 
  endwhile
  return attributes
endfunction


function! s:get_filename()
  return expand("%:p")
endfunction


function! s:send_message_to_debugger(message)
  call system("ruby -e \"require 'socket'; a = TCPSocket.open('localhost', 39768); a.puts('" . a:message . "'); a.close\"")
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



