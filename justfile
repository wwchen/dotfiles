# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

secrets := "secrets/infra.sops.yaml"
ansible_dir := "infra/ansible"

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Set up / re-check this Mac (interactive)
[group('mac')]
bootstrap *args:
    ./bootstrap.sh {{ args }}

# Show what `apply` would change in your home folder (uses this checkout)
[group('mac')]
diff:
    chezmoi --source {{ justfile_directory() }} diff

# Apply dotfiles; installs anything missing from the Brewfiles
[group('mac')]
apply:
    chezmoi --source {{ justfile_directory() }} apply -v

# Dry run of apply: list every file and script it would change or run, change nothing
[group('mac')]
apply-dry:
    chezmoi --source {{ justfile_directory() }} apply --dry-run --verbose

# Walk through installed-vs-Brewfile drift and update the Brewfiles
[group('mac')]
brew-sync:
    scripts/brew-sync

# Report Brewfile drift only (exit 1 if any)
[group('mac')]
brew-check:
    scripts/brew-sync --check

# Save iTerm2's "Default" profile (the one to tweak in Settings) into the repo
[group('mac')]
iterm-export profile="Default":
    scripts/iterm-export "{{ profile }}"
    @echo "Next: git diff to review, then 'just apply' to load it into iTerm2."

# Create secrets/infra.sops.yaml from the example (once)
[group('secrets')]
secrets-init:
    #!/usr/bin/env bash
    set -euo pipefail
    test ! -e {{ secrets }} || { echo "{{ secrets }} already exists"; exit 1; }
    # Encrypt via a temp file so a sops failure never leaves plaintext at the real path.
    tmp="secrets/.tmp-$$.sops.yaml"
    trap 'rm -f "$tmp" "$tmp.enc"' EXIT
    cp secrets/infra.example.yaml "$tmp"
    sops encrypt "$tmp" > "$tmp.enc"
    mv "$tmp.enc" {{ secrets }}
    echo "Now run: just secrets-edit"

# Edit encrypted secrets in $EDITOR
[group('secrets')]
secrets-edit:
    sops {{ secrets }}

# Dry run: show what would change on a host (or group)
[group('pis')]
pi-check host="all" *args:
    @just _ansible --check --diff --limit {{ host }} {{ args }}

# Apply the playbook to a host (or group)
[group('pis')]
pi-apply host="all" *args:
    @just _ansible --diff --limit {{ host }} {{ args }}

[private]
_ansible *args:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ ansible_dir }} && ansible-playbook site.yml {{ args }}

# Lint everything (shell, ansible)
[group('checks')]
lint:
    shellcheck bootstrap.sh scripts/*
    cd {{ ansible_dir }} && ansible-lint
