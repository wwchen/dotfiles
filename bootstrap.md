## vim
```
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
```


## zsh set up
# oh-my-zsh
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

# zsh theme: powerlevel
```
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

# zsh plugin: zsh-autosuggestion
```
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

`.zshrc`:
```
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# https://unix.stackexchange.com/questions/116562/key-bindings-table?rq=1
bindkey '^?^I' autosuggest-accept     # <opt-tab>
alias reload='source ~/.zshrc'
setopt no_share_history
```

# brew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## git setup
```
git config --global alias.s status
git config --global alias.c checkout
git config --global alias.pr "push --set-upstream origin HEAD"
git config --global user.name "William Chen""
git config --global user.email github@iamchen.com
```

## mac apps
### app store
- [magnet](https://apps.apple.com/us/app/magnet/id441258766?mt=12), or
- [rectangle](https://rectangleapp.com/)
- [amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12)

### others
- sublime
- 1password
- istat pro
- 
