# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Bootstrap: Homebrew, then chezmoi, just and gh; prints the commands to finish setup
[group('mac')]
bootstrap:
    ./bootstrap.sh

# Show what `apply` would change in your home folder (uses this checkout)
[group('mac')]
diff: _init
    chezmoi --source {{ justfile_directory() }} diff

# Show what applying this repo would change, ask, then apply (-y: don't ask)
[group('mac')]
apply *args: _init
    @scripts/apply {{ args }}

# First diff/apply on this Mac: chezmoi asks its questions (machine type, email, ...) once
[private]
_init:
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ ! -f "${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml" ]]; then
      echo "First run on this Mac: a few questions, saved in ~/.config/chezmoi/chezmoi.toml."
      chezmoi init --source {{ justfile_directory() }}
    fi

# Lint shell scripts
[group('checks')]
lint:
    shellcheck bootstrap.sh scripts/*
