#!/usr/bin/env bash

# Iter 1 - back up originals, symlink files to github

shopt -s dotglob # We want to glob dotfiles!

apps=(bash vim git rails tmux irssi)

##
# Functions
##

# Symlink everything from here to whatever the current homedir is
function preserve
{
  if [[ -f $1 ]]; then
    mv -i $1 $1.orig
  fi
}

##
# Go through all da apps!
##
for app in "${apps[@]}"; do
  if [[ $app == "bash" ]]; then
    preserve .bashrc
    cp -a .bashrc ~
    break
  fi
  if [[ $app == "vim" ]]; then
    preserve .vimrc
    cp -a .vimrc ~
mkdir ~/.vim
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
# put in the vundle part
vim +BundleInstall +qall
# put in the shortcuts
    break
  fi
done

# Glob all dotfiles with a few exceptions
# Now I don't have to update this script much in the future!
#preserve_stuff !(.git|.gitignore|*.swp|README.md|bootstrap.sh|bash_shenanigans.sh|.irssi)
preserve_stuff .screenrc
preserve_stuff .tmux.conf
preserve_stuff .vim
preserve_stuff .vimrc
preserve_stuff .gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# Now for the magic where I append my bash stuff onto 
# the existing bash_profile without causing problems (in theory...)
if ! grep -q ". $PWD/bash_shenanigans.sh" ~/.bash_profile 
then
	echo "Appending bash_shenanigans.sh to ~/.bash_profile"
	echo ". $PWD/bash_shenanigans.sh" >> ~/.bash_profile
fi

# vim stuff
#git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
#vim +BundleInstall +qall
