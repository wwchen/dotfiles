# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## New Mac

```bash
curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/bootstrap.sh | bash
```

`bootstrap.sh` runs in three phases, asking before each, and only does what's missing on re-runs:

1. **Prerequisites:** Command Line Tools, Homebrew.
2. **Core apps:** `brew/Brewfile.core` (CLI basics, 1Password, iTerm2), read from GitHub (no clone yet),
   listed first. The other groups install on `just apply`.
3. **Setup:** `gh` login, then checks your SSH key is on GitHub. It never makes or uploads a key:
   if one is missing it prints the commands for you to run, then you re-run. Then it asks where
   your code lives (default `~/code`), clones this repo over SSH to `<that>/wwchen/dotfiles` and
   offers `just apply`.

`just apply` shows what it would change and asks before doing anything. The first run asks
machine type and email, once.

## Day to day

```bash
just              # fuzzy-pick a command (or `just -l` to list, `just <Tab>` to complete)
just diff         # what would change in ~
just apply        # show what would change, confirm, apply (`just apply -y` skips the question)
```
