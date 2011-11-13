# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc) for examples
# color examples: https://wiki.archlinux.org/index.php/Color_Bash_Prompt

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
HISTCONTROL=$HISTCONTROL${HISTCONTROL+:}ignoredups
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

color_prompt=yes

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt


# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


###########################################
## Custom stuff
###########################################
mkcd() {
	mkdir -p "$*"
	cd "$*"
}

alias ll='ls -lh --color=auto'
alias sl='ls'
alias l='ls'
#alias du='du -h --max-depth=1'
alias df='df -h'
#alias cp='cp -a'
alias ldaptamu='/usr/bin/ldapsearch -x -h operator.tamu.edu'
#PS1='${debian_chroot:+($debian_chroot)}\[\033[01;33m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
alias cdres='cd ~/Dropbox/Documents/Professional/Resume'
alias echoempty='for file in * ; do if [ `cat $file | wc -l` -lt 3 ]; then echo $file; fi; done;'
alias rmempty='for file in * ; do if [ `cat $file | wc -l` -lt 3 ]; then rm $file; fi; done;'
#alias csweather="weather -i KCLL; echo ---------; weather -c 'College Station' -s TX -f"
alias csweather="weather -c 'College Station' -s TX -f -i KCLL"

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

source ~/.bookmarks

#alias rntv='for i in *.avi; do mv $i "$( echo $i | sed -e 's/\.[hH][dD][tT][vV].*$//' -e 's/\./ /g' -e 's/$/.avi/')"; done'
#alias primehost='for i in `grep prime /var/log/apache2/*access* | cut -d" " -f1 | cut -d: -f2 | sort | uniq`; do host $i; done'

# alt+shift+[

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
