#!/bin/bash

# move the old config to backup
[[ -f ~/.vimrc ]] && echo ".vimrc already exists. Moving to .vimrc.orig" && mv ~/.vimrc ~/.vimrc.orig

# copy my copy to home
cp -a .vimrc ~/

# set up vundle
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
vim +BundleInstall +qall
