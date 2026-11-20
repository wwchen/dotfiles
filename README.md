# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Dotfiles (zsh, git, starship) | [chezmoi](https://chezmoi.io) | `home/` |
| Mac apps & CLIs | Homebrew Bundle (+ `mas`) | `brew/Brewfile.core` (bootstrap), `.apps`, opt-in `.dev`, `.personal` / `.work` |
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## Getting started

On a new Mac, run these one at a time:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# What the rest of setup needs
brew install chezmoi just gh

# Log in to GitHub, then clone
gh auth login
gh repo clone wwchen/dotfiles ~/code/wwchen/dotfiles

# Set up this Mac
cd ~/code/wwchen/dotfiles && just apply
```

`just apply` shows what it would change and asks before doing anything. The first run asks
machine type, email and dev tools, once.

Everything else is data: setup steps live in [`home/.chezmoidata/steps.yaml`](home/.chezmoidata/steps.yaml)
(name, a `check` command, and a `run` command or a `hint`). Every `just apply` runs the steps whose
check fails, asking first unless `ask: false`; add a step there instead of editing a script.

## Day to day

```bash
just              # fuzzy-pick a command (or `just -l` to list, `just <Tab>` to complete)
just diff         # what would change in ~
just apply        # show what would change, confirm, apply (`just apply -y` skips the question)
just brew-sync    # installed something by hand? add it to a Brewfile (or ignore/uninstall)
```

Edit dotfiles in `home/` (or `chezmoi edit ~/.zshrc`), never in `~` directly.
Per-machine untracked overrides: `~/.zshrc.local`, `~/.gitconfig.local`.
