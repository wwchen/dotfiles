# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Show what `apply` would change in ~
[group('mac')]
diff: _init
    chezmoi --source "{{ justfile_directory() }}" diff

# Plan, confirm, apply (-y: don't ask)
[group('mac')]
apply *args: _init
    @scripts/apply {{ args }}

# Regenerate chezmoi's config; asks only questions this Mac hasn't answered.
[private]
_init:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! chezmoi init --source "{{ justfile_directory() }}"; then
      echo "chezmoi init failed. If it had questions to ask, run this in a terminal." >&2
      exit 1
    fi

# Walk through Brewfile drift and fix it
[group('mac')]
brew-sync:
    scripts/brew-sync

# Report Brewfile drift (exit 1 if any)
[group('mac')]
brew-check:
    scripts/brew-sync --check

# Save iTerm2's "Default" profile into the repo
[group('mac')]
iterm-export profile="Default":
    scripts/iterm-export "{{ profile }}"
    @echo "Next: git diff to review, then 'just apply' to load it into iTerm2."

# Pick an iTerm2 color theme, or pass a name
[group('mac')]
[positional-arguments]
iterm-theme *args:
    @scripts/iterm-theme "$@"

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
