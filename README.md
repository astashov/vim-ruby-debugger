# Disclaimer #

This is a new version of the plugin, which uses **debugger-xml** gem, and works only with Ruby >= 1.9. If you want to use **ruby-debug-ide** gem and/or Ruby <= 1.8.7, you should check 'v1.0' branch (http://github.com/astashov/vim-ruby-debugger/tree/v1.0)

# Description #

This Vim plugin implements interactive Ruby debugger in Vim.

This version of the plugin works only with Ruby >= 1.9. It uses [**debugger-xml**](https://rubygems.org/gems/debugger-xml) under the hood, which is just a XML/IDE extension for the [**debugger**](https://rubygems.org/gems/debugger) gem, which supports Ruby 1.9.2 and 1.9.3 out-of-the-box, but doesn't support Ruby <= 1.8.7.

# Features #

1. It can debug any Ruby application (Rails, by default), **debugger-xml** gem
2. The debugger looks like in any IDE - you can go through the code, watch variables, breakpoints in a separate window, set and remove breakpoints.
3. It supports execution of commands in the context of stopped line. E.g., you can execute ':RdbEval User.all' in the Vim command line and it will display the results like usual echo Vim command.


# Requirements #

1.  Vim >= 7.0, compiled with +signs, +clientserver and +ruby. You can verify it by VIM command:

        :echo has("signs") && has("clientserver") && has("ruby") && v:version > 700

    It should show result '1'.

2.  debugger-xml gem.
3.  For OS X:

    The vim that ships with OS X does not use ruby, nor does it support --servername, so MacVim must be used.

    Make sure that both MacVim, and mvim are installed.

    If they are not, you can use homebrew (http://mxcl.github.com/homebrew/):

        brew install macvim

    This will install MacVim, along with the mvim command line utility.

# Installation #

1.  Clone the repo

        git clone git://github.com/astashov/vim-ruby-debugger.git

    or just download the archive from here:

        http://github.com/astashov/vim-ruby-debugger/tarball/master

    You will get the 'vim-ruby-debugger' dir with the plugin.

2.  Copy contents of the 'vim-ruby-debugger' dir to your ~/.vim/ (or to ~/.vim/bundle/vim-ruby-debugger if you use pathogen).

3.  Generate the local tags file

        :helptags ~/.vim/doc

    Now, you can use

        :help ruby-debugger

    to get help for the ruby-debugger plugin.

4.  If using MacVim:

    Modify your ~/.vimrc to add the following line:

    ```VimL
    let g:ruby_debugger_progname = 'mvim'
    ```

Windows is not supported, sorry, Windows users.


# Using #

1.  Run Vim. If you use gvim/mvim, it will automatically start the server, but if you use vim, you need to set
    servername explicitly, e.g., **vim --servername VIM**

2.  Go to the directory with some your Rails application.

         :cd ~/projects/rails

3.  Run Server with Debugger:

         :Rdebugger

    It will run debugger-xml's rdebug-vim executable, create a UNIX socket in tmp directory,
    and connect to debugger-xml through it.

3.  Set a breakpoint somewhere by **&lt;Leader&gt;b** (e.g., '\b'). You should see 'xx' symbol at current line.

4.  Open a page with the breakpoint in a browser. Vim should automatically set the current line to the breakpoint.

5.  After this, you can use commands:

         <Leader>b - set breakpoint at current line
         <Leader>v - open/close window with variables. You can expand/collapse variables by 'o' in normal mode or left-mouse double-click
         <Leader>n - step over
         <Leader>s - step into
         <Leader>c - continue

6.  You may find useful to override default shortcut commands by F5-F8 shortcuts. Add these to your .vimrc:

          map <F7>  :call g:RubyDebugger.step()<CR>
          map <F5>  :call g:RubyDebugger.next()<CR>
          map <F8>  :call g:RubyDebugger.continue()<CR>

# Testing #

If you want to run tests, replace in /autoload directory ruby_debugger.vim to **ruby_debugger.vim** from additionals/autoload directory.
And then, in command mode execute

         :call g:TU.run()


# Screenshot #

![Screenshot](https://raw.github.com/astashov/vim-ruby-debugger/master/screenshot.png)


# Thanks #

Special thanks to tpope (for rails.vim) and Marty Grenfell (for NERDTree), mostly, I learn Vim Scripting from their projects.
