# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Dotfiles (zsh, git, starship) | [chezmoi](https://chezmoi.io) | `home/` |
| Mac apps & CLIs | Homebrew Bundle (+ `mas`) | `brew/Brewfile`, `brew/Brewfile.{personal,work}` |
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## Day to day

```bash
just              # fuzzy-pick a command (or `just -l` to list, `just <Tab>` to complete)
just diff         # what would change in ~
just apply        # apply dotfiles, and install anything missing from the Brewfiles
just apply-dry    # dry run: what apply would change or run, changing nothing
just brew-sync    # installed something by hand? add it to a Brewfile (or ignore/uninstall)
```

Edit dotfiles in `home/` (or `chezmoi edit ~/.zshrc`), never in `~` directly.
Per-machine untracked overrides: `~/.zshrc.local`, `~/.gitconfig.local`.
