# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

secrets := "secrets/infra.sops.yaml"

# sops' macOS default is ~/Library/Application Support/sops/age/keys.txt; keep the key in ~/.config.
export SOPS_AGE_KEY_FILE := env("SOPS_AGE_KEY_FILE", home_directory() / ".config/sops/age/keys.txt")
ansible_dir := "infra/ansible"

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Save iTerm2's "Default" profile into the repo
[group('mac')]
iterm-export profile="Default":
    scripts/iterm-export "{{ profile }}"
    @echo "Next: git diff to review, then 'chezmoi apply' to load it into iTerm2."

# Create secrets/infra.sops.yaml (once)
[group('secrets')]
secrets-init:
    #!/usr/bin/env bash
    set -euo pipefail
    test ! -e {{ secrets }} || { echo "{{ secrets }} already exists"; exit 1; }
    # Via a temp file, so a failure never leaves plaintext behind.
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

# Dry run on a host or group
[group('pis')]
[positional-arguments]
pi-check host="all" *args:
    @just _ansible --check --diff --limit "$1" "${@:2}"

# Apply to a host or group
[group('pis')]
[positional-arguments]
pi-apply host="all" *args:
    @just _ansible --diff --limit "$1" "${@:2}"

[positional-arguments]
[private]
_ansible *args:
    #!/usr/bin/env bash
    set -euo pipefail
    cd {{ ansible_dir }}
    # Collections from requirements.yml that aren't installed yet.
    ansible-galaxy collection install -r requirements.yml -p ~/.ansible/collections >/dev/null
    ansible-playbook site.yml "$@"

# Lint shell and Ansible
[group('checks')]
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    files=(*.sh scripts/*)
    if (( ${#files[@]} )); then shellcheck "${files[@]}"; fi
    (cd {{ ansible_dir }} && ansible-lint)

# Run the test suite (tests/*.bats)
[group('checks')]
test:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    files=(tests/*.bats)
    if (( ${#files[@]} == 0 )); then echo "No tests yet (tests/*.bats)."; exit 0; fi
    bats "${files[@]}"
