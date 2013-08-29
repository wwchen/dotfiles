#!/bin/bash

cwd="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"

function sym-install {
  src=$1
  dst=$2
  [[ -z $dst ]] && dst=$src
  [[ -f "$HOME/$dst" ]] && mv "$HOME/$dst" "$HOME/$dst-"
  ln -s "$cwd/$src" "$HOME/$dst"
}

function install {
  src=$1
  dst=$2
  [[ -z $dst ]] && dst=$src
  [[ -f "$HOME/$dst" ]] && mv "$HOME/$dst" "$HOME/$dst-"
  cp -a "$cwd/$src" "$HOME/$dst"
}

function setup {
  name=$1
  echo -en "\e[33mSet up $1? [Yn]\e[0m "
  read ans
  [[ -z $ans ]] && ans="y"
  if [[ $ans == "y" || $ans == "Y" ]]; then
    # yes
    echo yes
  elif [[ $ans == "n" || $ans == "N" ]]; then
    # no
    echo no
  else
    # loop
    echo "Invalid response"
    setup $1
  fi
}

function notice {
  string=$*
  echo -e "\e[33m$string"
  sleep 2
}

# check if it is debian we are running herer

notice "Installing essential packages"
sudo apt-get update
sudo apt-get install git vim curl tmux uprecords-cgi vnstat

notice "Setup bash"
sym-install .bash_profile
sym-install .bashrc
touch $HOME/.bash_custom
notice "Put your custom crap in .bash_custom"
# if we're setting up tmux and ssh, automatically attach the tmux session to bash profile

notice "Setup git"
sym-install .gitignore_global
git config --global user.name William Chen
git config --global user.email williamchen16@gmail.com
git config --global help.autocorrect 1
git config --global core.excludesfile ~/.gitignore_global
#http://adit.io/posts/2013-08-16-five-useful-git-tips.html

notice "Setup tmux"
sym-nstall .tmux.conf

notice "Setup ruby with rails"
curl -L https://get.rvm.io | bash -s stable --rails

echo "Setup vim with vundle"
update-alternatives --config editor
sym-install .vimrc
git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
vim +BundleInstall +qall

echo "Setup ssh"
ssh-keygen
cat .ssh/id_rsa.pub >> "$cwd/ssh-authkeys"
install ssh-authkeys .ssh/authorized_keys

echo "Setup iptables"

echo "Colorize root bash"
