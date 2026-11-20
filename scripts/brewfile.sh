# shellcheck shell=bash
# Brewfile helpers, sourced (not run) by scripts/brew-sync and the brew step
# (home/run_after_10-brew-bundle.sh.tmpl). bootstrap.sh keeps its own copy of
# brewfile_entries and brewfile_pending, since it runs before this repo is cloned;
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

brewfile_pending() {  # brewfile_pending FILE -> names of entries brew says need something
  # brew bundle check lists them on stderr, worded per kind: "→ Formula jq needs to be
  # installed.", "→ Tap x needs to be tapped.", "→ Formula libpq needs to be linked.",
  # "→ npm Package y needs to be installed.", ... Matching each entry's own name copes with all
  # of those. Returns 2 (with brew's output on stderr) if the check failed but named none of
  # the entries, e.g. a broken Brewfile.
  local out name found=0
  out="$(brew bundle check --no-upgrade --verbose --file="$1" 2>&1)" && return 0
  while IFS= read -r name; do
    if grep -qF " $name needs to be " <<<"$out"; then echo "$name"; found=1; fi
  done < <(brewfile_entries "$1" | awk '!seen[$0]++')   # each name once, even if listed twice
  (( found )) && return 0
  echo "$out" >&2
  return 2
}
