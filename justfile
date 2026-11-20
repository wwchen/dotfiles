# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Show what `apply` would change in your home folder (uses this checkout)
[group('mac')]
diff: _init
    chezmoi --source "{{ justfile_directory() }}" diff

# Show what applying this repo would change, ask, then apply (-y: don't ask)
[group('mac')]
apply *args: _init
    @scripts/apply {{ args }}

# Before every diff/apply: regenerate chezmoi's config from home/.chezmoi.toml.tmpl. Questions
# are only asked for answers this Mac doesn't have yet: the first run, or one added since.
[private]
_init:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! chezmoi init --source "{{ justfile_directory() }}"; then
      echo "chezmoi init failed. If it had questions to ask, run this in a terminal." >&2
      exit 1
    fi

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

# Lint shell scripts
[group('checks')]
lint:
    shellcheck scripts/*

# Run the test suite (tests/*.bats)
[group('checks')]
test:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    files=(tests/*.bats)
    if (( ${#files[@]} == 0 )); then echo "No tests yet (tests/*.bats)."; exit 0; fi
    bats "${files[@]}"
