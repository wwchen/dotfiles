# shellcheck shell=bash
# Brewfile helpers (sourced). Names match literally and may contain spaces.

brewfile_entries() {  # brewfile_entries FILE -> each entry's name, one per line, in file order
  sed -nE 's/^[[:space:]]*(tap|brew|cask|mas|npm) "([^"]+)".*/\2/p' "$1"
}

brewfile_pending() {  # brewfile_pending FILE -> names of entries brew says need something
  # Matches "→ <Kind> <name> needs to be ..." on stderr. Returns 2 if the check failed
  # without naming any entry (e.g. a broken Brewfile).
  local out name found=0
  out="$(brew bundle check --no-upgrade --verbose --file="$1" 2>&1)" && return 0
  while IFS= read -r name; do
    if grep -qF " $name needs to be " <<<"$out"; then echo "$name"; found=1; fi
  done < <(brewfile_entries "$1" | awk '!seen[$0]++')   # each name once, even if listed twice
  (( found )) && return 0
  echo "$out" >&2
  return 2
}
