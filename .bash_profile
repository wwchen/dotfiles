source ~/.profile

#PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# some more ls aliases
alias ls='ls -G'
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'
alias sl='ls'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
#alias du='du -h -d=1'
alias df='df -h'
#alias cp='cp -a'

mkcd() {
	mkdir -p "$*"
	cd "$*"
}
command_exists() {
  type "$1" &> /dev/null
}

alias ldaptamu='/usr/bin/ldapsearch -x -h operator.tamu.edu'

# Bash Directory Bookmarks
# ref: http://www.huyng.com/archives/quick-bash-tip-directory-bookmarks/492/
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
alias p2ds='/Users/wchen/Dropbox/Shared-with-Emily/print_jobs/p2/two-sided-long-edge'

source ~/.bookmarks
EDITOR=vim
[[ -s "/Users/wchen/.rvm/scripts/rvm" ]] && source "/Users/wchen/.rvm/scripts/rvm"  # This loads RVM into a shell session.

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

#PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]] \u@\[\]\w\[${c_sgr0}\]: '
#PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

#PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]] ${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
USERCLR='01;32m'
HOSTCLR="01;31m"
DIRCLR='01;34m'

if command_exists md5sum; then
  md5="md5sum"
elif command_exists md5; then
  md5="md5"
fi
if [ -n $md5 ]; then
  hosthash=$(hostname | $md5 | sed 's/[^0-9]//g')
  userhash=$(whoami   | $md5 | sed 's/[^0-9]//g')
  let "hostcolor = ${hosthash:0:8} % 7 + 30"
  let "usercolor = ${userhash:0:8} % 7 + 30"
  HOSTCLR="01;${hostcolor}m"
  USERCLR="01;${usercolor}m"
  unset hosthash hostcolor userhash usercolor
fi

PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]] ${debian_chroot:+($debian_chroot)}\[\033[$USERCLR\]\u\[\033[00m\]@\[\033[$HOSTCLR\]\h\[\033[00m\]:\[\033[$DIRCLR\]\w\[\033[00m\]\$ '
