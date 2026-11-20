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
diff:
    chezmoi --source {{ justfile_directory() }} diff

# Apply dotfiles; also runs brew bundle / iTerm2 scripts when their inputs changed
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

# Lint shell scripts
[group('checks')]
lint:
    shellcheck scripts/*
