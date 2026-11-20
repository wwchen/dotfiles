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

function ask {
  question=$1
  echo -en "\e[33m$question?\e[0m [Yn]"
  read ans
  [[ -z $ans ]] && ans="y"
  if [[ $ans == "y" || $ans == "Y" ]]; then
    return 0  # return 0 for true
  elif [[ $ans == "n" || $ans == "N" ]]; then
    return 1  # return 1 for false
  else
    echo "Invalid response"
    ask $question
  fi
}

function notice {
  string=$*
  echo -e "\e[33m$string"
}

# TODO check if it is debian we are running here

if ask "Install essential packages"; then
  sudo apt-get update
  sudo apt-get install git vim curl tmux uprecords-cgi vnstat
else notice "Skipped"; fi

if ask "Setup bash"; then
  sym-install .bash_profile
  sym-install .bashrc
  touch $HOME/.bash_custom
  notice "Put your custom crap in .bash_custom"
  # if we're setting up tmux and ssh, automatically attach the tmux session to bash profile
else notice "Skipped"; fi

if ask "Setup git"; then
  sym-install .gitignore_global
  git config --global user.name William Chen
  git config --global user.email williamchen16@gmail.com
  git config --global help.autocorrect 1
  git config --global core.excludesfile ~/.gitignore_global
  git config --global alias.latest "for-each-ref --count=10 --sort=-committerdate --format='%(committerdate:short) %(refname:short)'"
  #http://adit.io/posts/2013-08-16-five-useful-git-tips.html
else notice "Skipped"; fi

if ask "Setup tmux"; then
  sym-install .tmux.conf
else notice "Skipped"; fi

if ask "Setup ruby with rails"; then
  curl -L https://get.rvm.io | bash -s stable --rails
else notice "Skipped"; fi

if ask "Setup vim with vundle"; then
  update-alternatives --config editor
  sym-install .vimrc
  git clone https://github.com/gmarik/vundle.git ~/.vim/bundle/vundle
  vim +BundleInstall +qall
fi

if ask "Setup ssh"; then
  ssh-keygen
  cat .ssh/id_rsa.pub >> "$cwd/ssh-authkeys"
  install ssh-authkeys .ssh/authorized_keys
else notice "Skipped"; fi

if ask "Setup iptables"; then
  install firewall.sh /root/firewall.sh
  sudo /root/firewall.sh
else notice "Skipped"; fi

if ask "Colorize root bash"; then
  echo "blah"
else notice "Skipped"; fi
