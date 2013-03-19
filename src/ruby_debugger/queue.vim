" *** Queue class (start)

let s:Queue = {}

" ** Public methods

" Constructor of new queue.
function! s:Queue.new() dict
  let var = copy(self)
  let var.queue = []
  let var.after = ""
  return var
endfunction


" Execute next command in the queue and remove it from queue
function! s:Queue.execute() dict
  if !empty(self.queue)
    call s:log("Executing queue")
    let message = join(self.queue, ';')
    call self.empty()
    call g:RubyDebugger.send_command(message)
  endif
endfunction


" Execute 'after' hook only if queue is empty
function! s:Queue.after_hook() dict
  if self.after != "" && empty(self.queue)
    call self.after()
  endif
endfunction


function! s:Queue.add(element) dict
  call s:log("Adding '" . a:element . "' to queue")
  call add(self.queue, a:element)
endfunction


function! s:Queue.empty() dict
  let self.queue = []
endfunction


" *** Queue class (end)



