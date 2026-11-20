# If not running interactively, don't do anything
[ -z "$PS1" ] && return
# If not running in a screen, start one up and use it
#[ -z "$STY" ] && exec screen -xRR
[[ $TERM != "screen" ]] && tmux attach && exit    # $TMUX
[[ -s "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
