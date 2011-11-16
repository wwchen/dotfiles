# If not running interactively, don't do anything
[ -z "$PS1" ] && return
# If not running in a screen, start one up and use it
#[ -z "$STY" ] && exec screen -xRR
[[ $TERM != "screen" ]] && tmux attach && exit    # $TMUX

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

if [ -f ~/.bashrc ]; then
  source ~/.bashrc
fi

##
# exports
##
export EDITOR=vim
export p2ss=/home/wchen/Dropbox/Shared-with-Emily/print_jobs/p2/single-sided/
export p2ds=/home/wchen/Dropbox/Shared-with-Emily/print_jobs/p2/two-sided-long-edge/
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

##
# git colors
##
c_cyan=`tput setaf 6`
c_red=`tput setaf 1`
c_green=`tput setaf 2`
c_sgr0=`tput sgr0`

parse_git_branch () {
  if git rev-parse --git-dir >/dev/null 2>&1;then
    gitver=$(git branch 2>/dev/null| sed -n '/^\*/s/^\* //p')
  else
    return 0
  fi
  echo -e $gitver
}

branch_color () {
if git rev-parse --git-dir >/dev/null 2>&1;then
  color=""
  if git diff --quiet 2>/dev/null >&2;then
    color="${c_green}"
  else
    color=${c_red}
  fi
else
  return 0
fi
echo -ne $color
}

