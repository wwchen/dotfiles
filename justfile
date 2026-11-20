# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Show what `apply` would change in your home folder
[group('mac')]
diff:
    chezmoi diff

# Apply dotfiles; also re-runs chezmoi scripts whose inputs changed
[group('mac')]
apply:
    chezmoi apply -v
