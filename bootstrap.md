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

# zsh plugin: gradle-completion
```
git clone https://github.com/gradle/gradle-completion ~/.oh-my-zsh/plugins/gradle-completion
```

`.zshrc`:
```
plugins+=(gradle-completion)
export PATH=".:$PATH"
```

`.zshrc`:
```
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-autosuggestions)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# https://unix.stackexchange.com/questions/116562/key-bindings-table?rq=1
bindkey '^?^I' autosuggest-accept     # <opt-tab>
alias reload='source ~/.zshrc'
alias zshrc='vim ~/.zshrc && reload'
setopt no_share_history
setopt no_nomatch
setopt no_extended_glob
setopt no_glob
```

## Sublime `subl` installation
https://www.sublimetext.com/docs/command_line.html#mac
```
echo 'export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"' >> ~/.zprofile
```

## Simple slack cli messenger
https://api.slack.com/apps/A05JDQT65LZ/install-on-team
```
echo "xorb-" > ~/.slack_busybee_alert_token.txt
```

```
### PERSONAL RELATED
function slack-alert {
    [[ -z $* ]] && echo "enter a message" && return 1
    # https://api.slack.com/apps/A05JDQT65LZ/install-on-team
    token="$(cat ~/.slack_busybee_alert_token.txt)"
    text="$*"
    channel="alerts"
    raw_response=$(curl -s -d "text=$text" -d "channel=$channel" -d "token=$token" -X POST https://slack.com/api/chat.postMessage)
    ok=$(echo "$raw_response" | jq .ok)
    echo "success: $ok"
    [[ $ok == "false" ]] && echo $raw_response
}
```


# brew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## git setup
```
git config --global alias.s status
git config --global alias.b branch
git config --global alias.c checkout
git config --global alias.pr "push --set-upstream origin HEAD"
git config --global alias.bb "for-each-ref --sort='-authordate:iso8601' --format=' %(authordate:relative)%09%(refname:short)' refs/heads"
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
