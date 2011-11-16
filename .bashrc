# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)

shopt -s histappend
shopt -s checkwinsize


###########################################
## Custom stuff
###########################################
mkcd() {
	mkdir -p "$*"
	cd "$*"
}
genpasswd() {
  local l=$1
  [ "$l" == "" ] && l=20
  tr -dc A-Za-z0-9_ < /dev/urandom | head -c ${l} | xargs
}

##
# aliases
##
alias ll='ls -lh --color=auto'
alias sl='ls'
alias l='ls'
alias du='du -h --max-depth=1'
alias df='df -h'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
#alias cp='cp -a'
alias ldaptamu='/usr/bin/ldapsearch -x -h operator.tamu.edu'
alias cdres='cd ~/Dropbox/Documents/Professional/Resume'
alias echoempty='for file in * ; do if [ `cat $file | wc -l` -lt 3 ]; then echo $file; fi; done;'
alias rmempty='for file in * ; do if [ `cat $file | wc -l` -lt 3 ]; then rm $file; fi; done;'
#alias csweather="weather -i KCLL; echo ---------; weather -c 'College Station' -s TX -f"
alias csweather="weather -c 'College Station' -s TX -f -i KCLL"
alias bing='cd /home/wchen/Dropbox/Documents/Professional/Microsoft/bing-mobile'
#alias rntv='for i in *.avi; do mv $i "$( echo $i | sed -e 's/\.[hH][dD][tT][vV].*$//' -e 's/\./ /g' -e 's/$/.avi/')"; done'
#alias refusedip="zgrep refused /var/log/auth.log* | awk '{print $NF}' | sed 's,[()],,g' | sort | uniq -c | sort -g"
alias primehost='for i in `grep prime /var/log/apache2/*access* | cut -d" " -f1 | cut -d: -f2 | sort | uniq`; do host $i; done'
#alias 463='for i in $(curl http://irl.cse.tamu.edu/courses/463/ 2>/dev/null | grep PDF | sed 's/.*<a href="\(.*\)".*/\1/'); do wget http://irl.cse.tamu.edu/courses/463/$i; done'
alias printcse='/home/wchen/bin/cronjobs/printd_cse.sh'
# alt+shift+[

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


#PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]] \u@\[\]\w\[${c_sgr0}\]: '
#PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

PS1='[\[$(branch_color)\]$(parse_git_branch)\[${c_sgr0}\]] ${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
