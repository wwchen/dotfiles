# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## Getting started

On a new Mac, run these one at a time:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# What the rest of setup needs
brew install chezmoi just gh

# Log in to GitHub (offers to make an SSH key and add it), then clone over SSH
gh auth login -h github.com -p ssh -w
gh repo clone wwchen/dotfiles ~/code/wwchen/dotfiles

# Set up this Mac
cd ~/code/wwchen/dotfiles && just apply
```

`just apply` shows what it would change and asks before doing anything. The first run asks
machine type and email, once.

## Day to day

```bash
just              # fuzzy-pick a command (or `just -l` to list, `just <Tab>` to complete)
just diff         # what would change in ~
just apply        # show what would change, confirm, apply (`just apply -y` skips the question)
```
