# shellcheck shell=bash
# Brewfile helpers (sourced). A key is "<type> <name>"; names match literally and may contain spaces.

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
