# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Save iTerm2's "Default" profile into the repo
[group('mac')]
iterm-export profile="Default":
    scripts/iterm-export "{{ profile }}"
    @echo "Next: git diff to review, then 'chezmoi apply' to load it into iTerm2."

# Pick an iTerm2 color theme, or pass a name
[group('mac')]
[positional-arguments]
iterm-theme *args:
    @scripts/iterm-theme "$@"

# Lint shell scripts
[group('checks')]
lint:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    files=(*.sh scripts/*)
    if (( ${#files[@]} )); then shellcheck "${files[@]}"; fi

# Run the test suite (tests/*.bats)
[group('checks')]
test:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    files=(tests/*.bats)
    if (( ${#files[@]} == 0 )); then echo "No tests yet (tests/*.bats)."; exit 0; fi
    bats "${files[@]}"
