# Description #

This Vim plugin implements interactive Ruby debugger in Vim.


# Features #

1. It can debug any Ruby application (Rails, by default), using **ruby-debug-ide** gem
2. The debugger looks like in the Netbeans - you can go through the code, watch variables, breakpoints in separate window, set and remove breakpoints.
3. It supports command-line rdebug commands. E.g., you can execute ':RdbCommand p User.all' in command line of VIM and it will display result like usual echo VIM command.


# Requirements #

1.  Vim >= 7.0, compiled with +signs and +clientserver. You can verify it by VIM command: 

        :echo has("signs") && has("clientserver") && v:version > 700

    It should show result '1'.

2.  ruby-debug-ide gem.
3.  For linux: 'lsof' program.


# Installation #

1.  Clone the repo

        git clone git://github.com/astashov/vim-ruby-debugger.git

2.  Copy contents of 'vim' folder to your ~/.vim/. You should have 3 files there then: **~/.vim/plugin/ruby_debugger.vim**, **~/.vim/bin/ruby_debugger.rb** and **~/.vim/doc/ruby_debugger.txt**
    First file is a debugger plugin and second is a small ruby script, that makes interaction between the VIM and the ruby-debug-ide gem. Third is documentation file.

3.  Generate local tags file
	
        :helptags ~/.vim/doc

    Now, you can use
    
        :help ruby-debugger
        
    to get help for the ruby-debugger plugin.

I've tested the plugin in Windows and Linux. All tests should be passed there.


# Using#

1.  Run Vim. If you use gvim, it will automatically start the server, but if you use vim, you need to set
    servername explicitly, e.g., **vim --servername VIM**

2.  Go to the directory with some your Rails application.
         
         :cd ~/projects/rails

3.  Run Server with Debugger:
   
         :Rdebugger

    It will kill any listeners of ports 39767 and 39768 and run rdebug-ide and ~/.vim/bin/ruby_debugger.rb on these ports accordingly.

3.  Set breakpoint somewhere by **&lt;Leader&gt;b** (e.g., '\b'). You should see 'xx' symbol at current line.

4.  Open page with the breakpoint in the browser. Vim should automatically set current line to breakpoint.

5.  After this, you can use commands:

         <Leader>b - set breakpoint at current line
         <Leader>v - open/close window with variables. You can expand/collapse variables by 'o' in normal mode or left-mouse double-click
         <Leader>n - step over
         <Leader>s - step into
         <Leader>c - continue


# Testing #

If you want to run tests, replace in /plugin directory ruby_debugger.vim to **ruby_debugger_test.vim** (take it from additionals/plugin directory).
And then, in command mode execute
  
         :call g:TU.run()


# Screenshot #

![Screenshot](http://astashov.net/images/vim_ruby_debugger.png)


# Thanks #

Special thanks to tpope (for rails.vim) and Marty Grenfell (for NERDTree), mostly, I learn Vim Scripting from their projects.
