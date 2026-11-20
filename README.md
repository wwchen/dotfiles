# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## New Mac

```bash
curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/bootstrap.sh | bash
```

`bootstrap.sh` only does what's missing, so it's safe to re-run:

1. **Prerequisites:** Command Line Tools, Homebrew.
2. **Core apps:** `brew/Brewfile.core` (CLI basics, 1Password, iTerm2), read from GitHub (no clone yet),
   listed first. Then a checklist of what's not installed yet, all ticked: space unticks, enter
   installs the rest. The other groups install on `just apply`.
3. **Next steps:** prints the commands to finish, leaving out what's already done. It runs
   none of them:

   ```bash
   gh auth login -h github.com -p ssh -w   # offers to make and add an SSH key to GitHub
   gh repo clone wwchen/dotfiles ~/code/wwchen/dotfiles   # over SSH; or clone anywhere
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
