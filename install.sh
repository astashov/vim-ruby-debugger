#!/bin/bash

rm /Users/anton/.vim//plugin/ruby_debugger.vim
rm /Users/anton/.vim//bin/ruby_debugger.rb
rm /Users/anton/.vim//autoload/ruby_debugger.vim

ln -s /Users/anton/projects/vim-ruby-debugger/vim/plugin/ruby_debugger.vim /Users/anton/.vim//plugin/ruby_debugger.vim
ln -s /Users/anton/projects/vim-ruby-debugger/vim/bin/ruby_debugger.rb /Users/anton/.vim//bin/ruby_debugger.rb
ln -s /Users/anton/projects/vim-ruby-debugger/additionals/autoload/ruby_debugger.vim /Users/anton/.vim//autoload/ruby_debugger.vim
