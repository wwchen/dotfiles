shopt -s histappend
shopt -s checkwinsize

# ---------------------------

##
# functions
##
mkcd() {
  mkdir -p "$*"
  cd "$*"
}

parse_git_branch() {
  if git rev-parse --git-dir >/dev/null 2>&1;then
    gitver=$(git branch 2>/dev/null| sed -n '/^\*/s/^\* //p')
  else
    return 0
  fi
  echo -e $gitver
}

branch_color() {
  c_cyan=`tput setaf 6`
  c_red=`tput setaf 1`
  c_green=`tput setaf 2`
  c_sgr0=`tput sgr0`
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

# ---------------------------

##
# exports
##
export EDITOR=vim

# ---------------------------

##
# aliases
##
# System
alias ls='ls -G --color=auto'
alias ll='ls -lhG'
alias sl='ls'
alias l='ls'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
# Custom
alias ldaptamu='/usr/bin/ldapsearch -x -h operator.tamu.edu'

# ---------------------------

##
# Bash Directory Bookmarks
# ref: http://www.huyng.com/archives/quick-bash-tip-directory-bookmarks/492/
##
alias m1='alias g1="cd \"`pwd`\""'
alias m2='alias g2="cd \"`pwd`\""'
alias m3='alias g3="cd \"`pwd`\""'
alias m4='alias g4="cd \"`pwd`\""'
alias m5='alias g5="cd \"`pwd`\""'
alias m6='alias g6="cd \"`pwd`\""'
alias m7='alias g7="cd \"`pwd`\""'
alias m8='alias g8="cd \"`pwd`\""'
alias m9='alias g9="cd \"`pwd`\""'
alias mdump='alias|grep -e "alias g[0-9]"|grep -v "alias m" > ~/.bookmarks'
alias lma='alias | grep -e "alias g[0-9]"|grep -v "alias m"|sed "s/alias //"'
if [ -f ~/.bookmarks ]; then
  source ~/.bookmarks
fi

# ---------------------------

##
# PS style
##
USERCLR='01;32m'
HOSTCLR="01;30m"
DIRCLR='01;34m'

PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]\e[0m] ${debian_chroot:+($debian_chroot)}\[\033[$USERCLR\]\u\[\033[00m\]@\[\033[$HOSTCLR\]\h\[\033[00m\]:\[\033[$DIRCLR\]\w\[\033[00m\]\$ '

# ---------------------------

