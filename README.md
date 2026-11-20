# dotfiles — personal infra

One repo for setting up my Macs and managing my remote boxes.

| What | Tool | Where |
|---|---|---|
| Dotfiles (zsh, git, starship) | [chezmoi](https://chezmoi.io) | `home/` |
| Mac apps & CLIs | Homebrew Bundle (+ `mas`) | `brew/Brewfile`, `brew/Brewfile.{personal,work}` |
| iTerm2 | Dynamic Profile + `defaults` | `home/Library/Application Support/iTerm2/`, `home/run_onchange_after_20-iterm2.sh.tmpl` |
| Raspberry Pis (TeslaMate, Tailscale, backups) | Ansible | `infra/ansible/` |
| Cloudflare Tunnel, DNS, Access | OpenTofu | `infra/cloudflare/` |
| Secrets | sops + age | `secrets/infra.sops.yaml` |
| Old configs (irssi, screen, 2013 bootstrap…) | — | `archive/` (not deployed) |

## New Mac

```bash
xcode-select --install
git clone https://github.com/wwchen/dotfiles ~/code/wwchen/dotfiles
~/code/wwchen/dotfiles/bootstrap.sh
```

`bootstrap.sh` asks before each step: Homebrew → chezmoi → (asks machine type + email) →
shows the dotfile diff → applies, which installs the Brewfiles, oh-my-zsh and the iTerm2 profile.
Re-running it is safe.

## Day to day

```bash
just              # fuzzy-pick a command (or `just -l` to list, `just <Tab>` to complete)
just diff         # what would change in ~
just apply        # apply dotfiles (re-runs brew bundle only when a Brewfile changed)
just brew-sync    # installed something by hand? add it to a Brewfile (or ignore/uninstall)
just iterm-export # tweaked iTerm2's "Default" profile in Settings? save it to the repo
```

**Changing the iTerm2 look:** edit the **Default** profile in iTerm2 Settings (not "wc" —
iTerm2 doesn't save Settings edits to dynamic profiles), then `just iterm-export`,
`git diff`, `just apply`, commit.

Edit dotfiles in `home/` (or `chezmoi edit ~/.zshrc`), never in `~` directly.
Per-machine untracked overrides: `~/.zshrc.local`, `~/.gitconfig.local`.

## Remote infra

```bash
just secrets-init     # once: create secrets/infra.sops.yaml from the example
just secrets-edit     # fill in Cloudflare/Tailscale/TeslaMate secrets

just cf-import        # once: generate import blocks for existing Cloudflare resources
just cf-plan          # preview Cloudflare changes (terraform-style plan)
just cf-apply

just pi-check pi-tx   # Ansible dry run with diff
just pi-apply pi-tx
```

- OpenTofu state is committed, encrypted with the passphrase in sops. No backend needed.
- The tunnel token flows OpenTofu → Ansible, so Cloudflare is the single source of truth.
- TeslaMate web UIs bind to `127.0.0.1` on the Pi; reach them through the tunnel (Access-protected).
- Nightly `pg_dump -Fc` to the USB drive, 14-day retention, healthchecks.io ping on success.

## Requirements

The age private key at `~/.config/sops/age/keys.txt` (keep a copy in your password manager).
Everything else comes from the Brewfile.
