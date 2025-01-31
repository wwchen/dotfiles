# vim
```
git clone --depth=1 https://github.com/amix/vimrc.git ~/.vim_runtime
sh ~/.vim_runtime/install_awesome_vimrc.sh
```

# brew
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

# zsh set up
## oh-my-zsh
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### zsh theme: powerlevel
[romkatv/powerlevel10k](https://github.com/romkatv/powerlevel10k?tab=readme-ov-file#oh-my-zsh)
``` bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

### zsh plugin: zsh-autosuggestion
[zsh-autosuggestion](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh)
``` bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

### zsh plugin: gradle-completion
``` bash
git clone https://github.com/gradle/gradle-completion ~/.oh-my-zsh/plugins/gradle-completion
```

## `.zshrc`
``` bash
plugins+=(gradle-completion)
export PATH=".:$PATH"

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

### attentive shortcuts
``` bash
# attentive
alias code="cd ~/code/attentive/code"
export ARTIFACTORY_USER="williamc@attentivemobile.com"
export ARTIFACTORY_API_KEY="$(security find-generic-password -s 'Attentive Artifactory' -w)"
alias attn-aws='/Users/wc/.aws_cli_script/.auto_configure_aws_cli_sso_roles.sh'
 alias ovpn="op item get OpenVPN --otp | pbcopy && '/Applications/OpenVPN Connect/OpenVPN Connect.app/contents/MacOS/OpenVPN Connect'"
 alias owners='f() { grep -vE "^/(contract|python|[^a-z])" ~/code/attentive/code/CODEOWNERS | grep -Ei "^/[a-z0-9-]*$1[a-z0-9-]*" }; f'
 alias sdm-all='sdm login --email williamc@attentivemobile.com && sdm connect -a'

 cid() {
     sql='select id, name, display_name, domain from companies where '
     [[ $1 =~ ^[0-9]+$ ]] && sql="$sql id = $1" || sql="$sql name like '%"$1"%'"
     [[ $2 == '-d' ]] && port=13306 || port=13377
     mysql -uuser -pp -h 127.0.0.1 -P $port -D attentive -e "$sql"
 }
```

## Simple slack cli messenger
https://api.slack.com/apps/A05JDQT65LZ/install-on-team
``` bash
echo "xorb-" > ~/.slack_busybee_alert_token.txt
```

``` bash
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

## Sublime `subl` installation
https://www.sublimetext.com/docs/command_line.html#mac
``` bash
echo 'export PATH="/Applications/Sublime Text.app/Contents/SharedSupport/bin:$PATH"' >> ~/.zprofile
```


# git setup
``` bash
git config --global alias.s status
git config --global alias.b branch
git config --global alias.c checkout
git config --global alias.pr "push --set-upstream origin HEAD"
git config --global alias.bb "for-each-ref --sort='-authordate:iso8601' --format=' %(authordate:relative)%09%(refname:short)' refs/heads"
git config --global user.name "William Chen""
git config --global user.email github@iamchen.com
```

# mac apps

## iterm setup
Profiles > General > Working Directory > Reuse previous session's directory
Profiles > Keys > Key Mappings > Presets > Natural Text Editing
Profiles > Keys > Key Mappings > Presets > Delete key sends ^H
Appearance > Dimming > (uncheck) Dim inactive split panes
General > Selection > (uncheck) Clicking on a command selects it to restrict Find and Filter

### app store
- [magnet](https://apps.apple.com/us/app/magnet/id441258766?mt=12), or
- [rectangle](https://rectangleapp.com/)
- [amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12)

### others
- sublime
- 1password
- istat pro
- 
