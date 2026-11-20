# shellcheck shell=bash
# Brewfile helpers, sourced (not run) by scripts/brew-sync and the brew step
# (home/run_after_10-brew-bundle.sh.tmpl). bootstrap.sh keeps its own copy of
# brewfile_entries and brewfile_missing, since it runs before this repo is cloned;
# keep the two in step.
#
# An entry is a `tap`, `brew`, `cask`, `mas` or `npm` line; its key is "<type> <name>".
# Names are matched literally (logi-options+, libsigc++) and may contain spaces (App Store apps).

brewfile_keys() {  # brewfile_keys FILE... -> "<type> <name>" per entry, sorted and unique
  sed -nE 's/^[[:space:]]*(tap|brew|cask|mas|npm) "([^"]+)".*/\1 \2/p' "$@" | sort -u
}

brewfile_entries() {  # brewfile_entries FILE -> each entry's name, one per line, in file order
  sed -nE 's/^[[:space:]]*(tap|brew|cask|mas|npm) "([^"]+)".*/\2/p' "$1"
}

brewfile_line() {  # brewfile_line KEY FILE -> the entry's full line, options (id:, link:) included
  awk -v p="${1%% *} \"${1#* }\"" 'index($0, p) == 1 { print; exit }' "$2"
}

brewfile_remove() {  # brewfile_remove KEY FILE -> drop the entry's line from FILE (no-op if absent)
  local type="${1%% *}" name="\"${1#* }\""
  awk -v t="$type" -v n="$name" '!($1 == t && index($0, t " " n) == 1)' "$2" > "$2.tmp" && mv "$2.tmp" "$2"
}

brewfile_missing() {  # brewfile_missing FILE -> names of entries that aren't installed, one per line
  # brew bundle reports these on stderr, as "→ <Type> <name> needs to be installed[ or updated]."
  brew bundle check --no-upgrade --verbose --file="$1" 2>&1 \
    | sed -nE 's/^→ [A-Za-z]+ (.+) needs to be installed.*/\1/p' || true
}
