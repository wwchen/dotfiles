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
alias ls='ls -G'
alias ll='ls -lhG'
alias sl='ls'
alias l='ls'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
# Custom
alias ldaptamu='/usr/bin/ldapsearch -x -h operator.tamu.edu'
alias cdres='cd ~/Dropbox/Documents/Professional/Resume'
alias csweather="weather -c 'College Station' -s TX -f -i KCLL"

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

##
# deprecated crap
##
#genpasswd() {
#  local l=$1
#  [ "$l" == "" ] && l=20
#  tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
#}
#command_exists() {
#  type "$1" &> /dev/null
#}
#alias echoempty='for file in * ; do if [ `cat $file | wc -l` -lt 3 ]; then echo $file; fi; done;'
#alias rmempty='for file in * ; do if [ `cat $file | wc -l` -lt 3 ]; then rm $file; fi; done;'
#alias csweather="weather -i KCLL; echo ---------; weather -c 'College Station' -s TX -f"
#alias rntv='for i in *.avi; do mv $i "$( echo $i | sed -e 's/\.[hH][dD][tT][vV].*$//' -e 's/\./ /g' -e 's/$/.avi/')"; done'
#alias refusedip="zgrep refused /var/log/auth.log* | awk '{print $NF}' | sed 's,[()],,g' | sort | uniq -c | sort -g"

#PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]] \u@\[\]\w\[${c_sgr0}\]: '
#PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
#PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# if [ -n `which md5sum` ]; then
#   md5="md5sum"
# elif [ -n `which md5` ]; then
#   md5="md5"
# fi
# if [ -n $md5 ]; then
#   hosthash=$(hostname | $md5 | sed 's/[^0-9]//g')
#   userhash=$(whoami   | $md5 | sed 's/[^0-9]//g')
#   let "hostcolor = ${hosthash:0:4} % 7 + 30"
#   let "usercolor = ${userhash:0:4} % 7 + 30"
#   HOSTCLR="01;${hostcolor}m"
#   USERCLR="01;${usercolor}m"
#   unset hosthash hostcolor userhash usercolor
# fi
#PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[$USERCLR\]\u\[\033[00m\]@\[\033[$HOSTCLR\]\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# alt+shift+[
