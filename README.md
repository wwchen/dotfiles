# dotfiles

My Macs and remote boxes.

| What | Tool | Where |
|---|---|---|
| Mac apps | [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile) | `brew/Brewfile.<group>` |
| Dotfiles (zsh, git, vim, ssh, iTerm2) | [chezmoi](https://chezmoi.io) | `home/` |
| Old configs | — | `archive/` (not deployed) |

## New Mac

```bash
curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/brew-install.sh | bash

# in a new terminal tab: clone to ~/code/wwchen/dotfiles and apply
chezmoi init --apply --source ~/code/wwchen/dotfiles wwchen
gh auth login && gh auth setup-git                   # to push changes
```

Already set up, with a checkout? From it: `chezmoi init --source "$PWD"`, check `chezmoi diff`,
move keepers to `~/.zshrc.local`, then `chezmoi apply` (`--apply` would overwrite `~/.zshrc`).

## Day to day

```bash
chezmoi update                                       # pull the repo, then apply
chezmoi edit --apply ~/.vimrc                        # edit a dotfile's source, apply on exit
chezmoi diff                                         # pending changes to ~, scripts included
chezmoi apply                                        # also sets up apps installed since
chezmoi apply -R                                     # same, and updates oh-my-zsh and vim-sensible

# in the checkout (chezmoi cd)
./brew-install.sh dev                                # install a group
brew bundle add --file=brew/Brewfile.dev ripgrep     # track + install (--cask for apps)
cat brew/Brewfile.* | brew bundle cleanup --file=-   # installed but untracked
just iterm-export                                    # after editing iTerm2's Default profile
```

Edit with `chezmoi edit` (or in `home/`), not in `~`. Per-machine: `~/.zshrc.local`, `~/.gitconfig`.
With Tailscale installed, `chezmoi apply` puts SSH aliases from `home/.chezmoidata/ssh.yaml`
in a marked section at the top of `~/.ssh/config` (`ssh pi-tx`); the rest of that file is kept.
