" *** RubyDebugger Commands *** 


" <breakpoint file="test.rb" line="1" threadId="1" />
" <suspended file='test.rb' line='1' threadId='1' />
function! RubyDebugger.commands.jump_to_breakpoint(cmd) dict
  let attrs = s:get_tag_attributes(a:cmd) 
  call s:jump_to_file(attrs.file, attrs.line)
  call g:RubyDebugger.logger.put("Jumped to breakpoint " . attrs.file . ":" . attrs.line)

  if has("signs")
    exe ":sign place " . s:current_line_sign_id . " line=" . attrs.line . " name=current_line file=" . attrs.file
  endif

  call g:RubyDebugger.send_command('var local')
endfunction


" <breakpointAdded no="1" location="test.rb:2" />
function! RubyDebugger.commands.set_breakpoint(cmd)
  let attrs = s:get_tag_attributes(a:cmd)
  let file_match = matchlist(attrs.location, '\(.*\):\(.*\)')
  " Set pid of current debugger to current breakpoint
  let pid = g:RubyDebugger.server.rdebug_pid

  for breakpoint in g:RubyDebugger.breakpoints
    if expand(breakpoint.file) == expand(file_match[1]) && expand(breakpoint.line) == expand(file_match[2])
      let breakpoint.debugger_id = attrs.no
      let breakpoint.rdebug_pid = pid
    endif
  endfor

  call g:RubyDebugger.logger.put("Breakpoint is set: " . file_match[1] . ":" . file_match[2])

  let not_assigned_breakpoints = filter(copy(g:RubyDebugger.breakpoints), '!has_key(v:val, "rdebug_pid") || v:val["rdebug_pid"] != ' . pid)
  let not_assigned_breakpoint = get(not_assigned_breakpoints, 0)
  if type(not_assigned_breakpoint) == type({})
    call not_assigned_breakpoint.send_to_debugger()
  else
    call g:RubyDebugger.send_command('start')
  endif
endfunction


" <variables>
"   <variable name="array" kind="local" value="Array (2 element(s))" type="Array" hasChildren="true" objectId="-0x2418a904"/>
" </variables>
function! RubyDebugger.commands.set_variables(cmd)
  let tags = s:get_tags(a:cmd)
  let list_of_variables = []

  for tag in tags
    let attrs = s:get_tag_attributes(tag)
    let variable = s:Var.new(attrs)
    call add(list_of_variables, variable)
  endfor

  if g:RubyDebugger.variables == {}
    let g:RubyDebugger.variables = s:VarParent.new({'hasChildren': 'true'})
    let g:RubyDebugger.variables.is_open = 1
    let g:RubyDebugger.variables.children = []
  endif

  if has_key(g:RubyDebugger, 'current_variable')
    let variable = g:RubyDebugger.current_variable
    if variable != {}
      call variable.add_childs(list_of_variables)
      call g:RubyDebugger.logger.put("Opening child variable: " . variable.attributes.objectId)
      call s:variables_window.open()
    else
      call g:RubyDebugger.logger.put("Can't found variable")
    endif
    unlet g:RubyDebugger.current_variable
  else
    if g:RubyDebugger.variables.children == []
      call g:RubyDebugger.variables.add_childs(list_of_variables)
      call g:RubyDebugger.logger.put("Initializing local variables")
      if s:variables_window.is_open()
        call s:variables_window.open()
      endif
    endif
  endif

endfunction


" <eval expression="User.all" value="[#User ... ]" />
function! RubyDebugger.commands.eval(cmd)
  " rdebug-ide-gem doesn't escape attributes of tag properly, so we should not
  " use usual attribute extractor here...
  let match = matchlist(a:cmd, "<eval expression=\"\\(.\\{-}\\)\" value=\"\\(.*\\)\" \\/>")
  echo "Evaluated expression:\n" . match[1] ."\nResulted value is:\n" . match[2] . "\n"
endfunction


" <error>Error</error>
function! RubyDebugger.commands.error(cmd)
  let error_match = s:get_inner_tags(a:cmd) 
  if !empty(error_match)
    let error = error_match[1]
    echo "RubyDebugger Error: " . error
    call g:RubyDebugger.logger.put("Got error: " . error)
  endif
endfunction


" <message>Message</message>
function! RubyDebugger.commands.message(cmd)
  let message_match = s:get_inner_tags(a:cmd) 
  if !empty(message_match)
    let message = message_match[1]
    echo "RubyDebugger Message: " . message
    call g:RubyDebugger.logger.put("Got message: " . message)
  endif
endfunction

" *** End of debugger Commands ***



