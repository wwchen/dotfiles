# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Core apps: CLI basics, 1Password, iTerm2, starship | Homebrew Bundle | `brew/Brewfile.core` |
| Their setup: `.zshrc`, starship preset, iTerm2 profile | [chezmoi](https://chezmoi.io) | `home/` |
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

`just apply` installs the core apps (`brew/Brewfile.core`) and sets them up. It shows what it
would change and asks before doing anything. The first run asks machine type and email, once.

An app's setup in `home/` is tied to the Brewfile entry that installs it: the iTerm2 profile
and settings only exist on Macs whose Brewfiles list `cask "iterm2"`, starship's only with
`brew "starship"`, and so on (`home/.chezmoitemplates/brew-listed`). The brew step reruns
whenever a Brewfile changes.

## Day to day

```bash
just              # fuzzy-pick a command (or `just -l` to list, `just <Tab>` to complete)
just diff         # what would change in ~
just apply        # show what would change, confirm, apply (`just apply -y` skips the question)
just iterm-export # tweaked iTerm2's "Default" profile in Settings? save it to the repo
```

**Changing the iTerm2 look:** edit the **Default** profile in iTerm2 Settings (not "wc" —
iTerm2 doesn't save Settings edits to dynamic profiles), then `just iterm-export`,
`git diff`, `just apply`, commit.
The export keeps only the settings that differ from iTerm2's factory defaults, so the
diff shows what you actually changed.

Edit dotfiles in `home/` (or `chezmoi edit ~/.zshrc`), never in `~` directly.
Per-machine untracked overrides: `~/.zshrc.local`.
