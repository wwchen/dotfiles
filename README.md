# dotfiles

My Macs and remote boxes.

| What | Tool | Where |
|---|---|---|
| Mac apps | [Homebrew Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile) | `brew/Brewfile.<group>` |
| Dotfiles (zsh, git, vim, ssh, iTerm2) | [chezmoi](https://chezmoi.io) | `home/` |
| Raspberry Pis | Ansible | `infra/ansible/` |
| Cloudflare tunnel, DNS, Access | OpenTofu | `infra/cloudflare/` |
| Secrets | sops + age | `secrets/` |
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

## Remote infra

Needs `./brew-install.sh infra` and the age key from your password manager:
`mkdir -p ~/.config/sops/age && (umask 077; set -C; pbpaste > ~/.config/sops/age/keys.txt)`

```bash
just secrets-init      # once
just secrets-edit
just cf-import         # once: adopt existing Cloudflare resources
just cf-plan
just cf-apply
just pi-check pi-tx    # dry run
just pi-apply pi-tx
```

Reflashed Pi (Raspberry Pi OS Lite, user `admin`, your SSH key): remove the old pi-tx from
Tailscale, then `just pi-apply pi-tx -e ansible_host=<LAN IP>`. Give `admin` an `accept` SSH rule
in the tailnet policy, or every run waits for a browser re-auth.

cloudflared runs on the Pi with its token from OpenTofu (state committed, encrypted). Before the
first `pi-apply` with it, stop any cloudflared started by hand
(`docker ps --format '{{.Names}} {{.Image}}' | grep cloudflared`).
`SKIP_TUNNEL_TOKENS=1 just pi-apply pi-tx --tags base,tailscale,docker` runs without the token.
