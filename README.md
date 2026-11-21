# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Mac apps & CLIs, in groups | [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile) | `brew/Brewfile.<group>` |
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## Getting started

On a new Mac, one at a time:

```bash
# Homebrew, then each Brewfile (lists it, asks Y/n), core first
curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/brew-install.sh | bash

# Clone, in a new terminal tab (it has Homebrew on PATH)
gh auth login
gh repo clone wwchen/dotfiles ~/code/wwchen/dotfiles && cd ~/code/wwchen/dotfiles
```

## Day to day

```bash
./brew-install.sh dev                               # one group again (-y: no question)
brew bundle add --file=brew/Brewfile.dev ripgrep   # track + install something new (--cask for apps)
brew bundle remove --file=brew/Brewfile.dev ripgrep
brew bundle check --file=brew/Brewfile.core         # anything missing?
cat brew/Brewfile.* | brew bundle cleanup --file=-          # installed but in no Brewfile (--force uninstalls)
```
