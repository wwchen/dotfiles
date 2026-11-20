# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Dotfiles (zsh, git, starship) | [chezmoi](https://chezmoi.io) | `home/` |
| Mac apps & CLIs | Homebrew Bundle (+ `mas`) | `brew/Brewfile`, `brew/Brewfile.{personal,work}`, opt-in `brew/Brewfile.dev` |
| iTerm2 | Dynamic Profile + `defaults` | `home/Library/Application Support/iTerm2/`, `home/run_onchange_after_20-iterm2.sh.tmpl` |
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## New Mac

```bash
xcode-select --install
git clone https://github.com/wwchen/dotfiles ~/code/wwchen/dotfiles
~/code/wwchen/dotfiles/bootstrap.sh
```

`bootstrap.sh` only gets chezmoi running: Command Line Tools → Homebrew → chezmoi (asks machine
type, email, dev tools) → shows the dotfile diff → applies. Re-running it is safe.

Everything else is data: setup steps live in [`home/.chezmoidata/steps.yaml`](home/.chezmoidata/steps.yaml)
(name, a `check` command, and a `run` command or a `hint`). Every `just apply` runs the steps whose
check fails, asking first unless `ask: false`; add a step there instead of editing a script.

## Day to day

```bash
just              # fuzzy-pick a command (or `just -l` to list, `just <Tab>` to complete)
just diff         # what would change in ~
just apply        # apply dotfiles, and install anything missing from the Brewfiles
just apply-dry    # dry run: what apply would change or run, changing nothing
just brew-sync    # installed something by hand? add it to a Brewfile (or ignore/uninstall)
just iterm-export # tweaked iTerm2's "Default" profile in Settings? save it to the repo
```

**Changing the iTerm2 look:** edit the **Default** profile in iTerm2 Settings (not "wc" —
iTerm2 doesn't save Settings edits to dynamic profiles), then `just iterm-export`,
`git diff`, `just apply`, commit.
The export keeps only the settings that differ from iTerm2's factory defaults, so the
diff shows what you actually changed.

Edit dotfiles in `home/` (or `chezmoi edit ~/.zshrc`), never in `~` directly.
Per-machine untracked overrides: `~/.zshrc.local`, `~/.gitconfig.local`.
