#!/usr/bin/env bats
# bootstrap.sh keeps its own copies of some Brewfile helpers: it runs before the repo is cloned
# (curl | bash), so it can't load scripts/brewfile.sh. Every brewfile_* function defined in
# both files must be identical, so a fix to one copy can't be forgotten in the other.
# Run: just test

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LIB="$ROOT/scripts/brewfile.sh"
  BOOT="$ROOT/bootstrap.sh"
  [ -f "$LIB" ] || skip "no scripts/brewfile.sh in this checkout yet"
}

names() { sed -nE 's/^(brewfile_[a-z_]+)\(\) \{.*/\1/p' "$1" | sort -u; }

body() {  # body NAME FILE -> the function, from its first line to the closing } at column 0
  awk -v n="$1" 'index($0, n "() {") == 1 { p = 1 } p { print } p && /^}$/ { exit }' "$2"
}

@test "bootstrap.sh's brewfile_* copies are identical to scripts/brewfile.sh's" {
  shared="$(comm -12 <(names "$LIB") <(names "$BOOT"))"
  for fn in $shared; do
    run diff -u --label "scripts/brewfile.sh: $fn" --label "bootstrap.sh: $fn" \
      <(body "$fn" "$LIB") <(body "$fn" "$BOOT")
    if [ "$status" -ne 0 ]; then
      echo "$output"
      echo "bootstrap.sh's copy of $fn differs from scripts/brewfile.sh: make them identical."
      return 1
    fi
  done
}

@test "the copies bootstrap.sh relies on exist in both files" {
  # bootstrap's phase 2 calls these two; if either is renamed in one file only, the check
  # above would silently stop covering it.
  for fn in brewfile_entries brewfile_pending; do
    grep -q "^$fn() {" "$LIB"
    grep -q "^$fn() {" "$BOOT"
  done
}
