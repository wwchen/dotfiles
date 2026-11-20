#!/usr/bin/env bats
# Unit tests for scripts/brewfile.sh. Run: just test
# `brew` is replaced by a fake (first on PATH) whose `bundle check` output each test sets.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # shellcheck source=../scripts/brewfile.sh
  source "$ROOT/scripts/brewfile.sh"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  BF="$BATS_TEST_TMPDIR/Brewfile"
  cat > "$BF" <<'EOF'
# a comment
tap "hashicorp/tap"
brew "jq"
brew "libpq", link: true
cask "logi-options+"
  cask "iterm2"
mas "Some Thing Pro", id: 123
npm "prettier"
brew "jq"
EOF
}

# fake_brew_check EXIT_STATUS [STDERR_TEXT] -> `brew bundle check` exits with that status,
# printing the text on stderr (where real brew prints what's missing)
fake_brew_check() {
  printf '%s\n' "${2:-}" > "$BATS_TEST_TMPDIR/check.out"
  cat > "$BATS_TEST_TMPDIR/bin/brew" <<EOF
#!/bin/bash
[[ "\$1 \$2" == "bundle check" ]] || { echo "unexpected: brew \$*" >&2; exit 99; }
cat "$BATS_TEST_TMPDIR/check.out" >&2
exit $1
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"
}

@test "brewfile_keys: '<type> <name>' per entry, sorted and unique; comments and options ignored" {
  run brewfile_keys "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' 'brew jq' 'brew libpq' 'cask iterm2' 'cask logi-options+' \
    'mas Some Thing Pro' 'npm prettier' 'tap hashicorp/tap')" ]
}

@test "brewfile_keys: several files at once" {
  printf 'cask "zoom"\nbrew "jq"\n' > "$BATS_TEST_TMPDIR/other"
  run brewfile_keys "$BF" "$BATS_TEST_TMPDIR/other"
  [[ "$output" == *"cask zoom"* ]]
  [ "$(grep -c '^brew jq$' <<<"$output")" -eq 1 ]
}

@test "brewfile_entries: names in file order, indented lines included" {
  run brewfile_entries "$BF"
  [ "${lines[0]}" = "hashicorp/tap" ]
  [ "${lines[3]}" = "logi-options+" ]
  [ "${lines[4]}" = "iterm2" ]
  [ "${lines[5]}" = "Some Thing Pro" ]
}

@test "brewfile_line: the full line, options kept" {
  run brewfile_line "brew libpq" "$BF"
  [ "$output" = 'brew "libpq", link: true' ]
  run brewfile_line "mas Some Thing Pro" "$BF"
  [ "$output" = 'mas "Some Thing Pro", id: 123' ]
}

@test "brewfile_line: names are literal, not regexes" {
  run brewfile_line "cask logi-options+" "$BF"
  [ "$output" = 'cask "logi-options+"' ]
  printf 'cask "logi-optionsss"\n' > "$BATS_TEST_TMPDIR/re"
  run brewfile_line "cask logi-options+" "$BATS_TEST_TMPDIR/re"
  [ -z "$output" ]
}

@test "brewfile_line: only the requested type matches" {
  run brewfile_line "cask jq" "$BF"
  [ -z "$output" ]
}

@test "brewfile_remove: drops exactly that entry and keeps everything else" {
  before="$(wc -l < "$BF")"
  brewfile_remove "cask logi-options+" "$BF"
  ! grep -q 'logi-options' "$BF"
  [ "$(wc -l < "$BF")" -eq $((before - 1)) ]
  grep -q '^# a comment$' "$BF"
}

@test "brewfile_remove: names with spaces" {
  brewfile_remove "mas Some Thing Pro" "$BF"
  ! grep -q 'Some Thing Pro' "$BF"
}

@test "brewfile_remove: absent entry is a no-op" {
  cp "$BF" "$BATS_TEST_TMPDIR/orig"
  brewfile_remove "brew not-there" "$BF"
  cmp -s "$BF" "$BATS_TEST_TMPDIR/orig"
}

@test "brewfile_remove: a prefix of another name is not removed with it" {
  printf 'brew "jq"\nbrew "jqp"\n' > "$BATS_TEST_TMPDIR/p"
  brewfile_remove "brew jq" "$BATS_TEST_TMPDIR/p"
  [ "$(cat "$BATS_TEST_TMPDIR/p")" = 'brew "jqp"' ]
}

@test "brewfile_pending: nothing when brew bundle check passes" {
  fake_brew_check 0
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "brewfile_pending: formulae, casks and App Store apps to install" {
  fake_brew_check 1 "brew bundle can't satisfy your Brewfile's dependencies.
→ Formula jq needs to be installed.
→ Cask iterm2 needs to be installed or updated.
→ App Some Thing Pro needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' jq iterm2 'Some Thing Pro')" ]
}

@test "brewfile_pending: taps, link changes and npm packages count too" {
  fake_brew_check 1 "→ Tap hashicorp/tap needs to be tapped.
→ Formula libpq needs to be linked.
→ npm Package prettier needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' hashicorp/tap libpq prettier)" ]
}

@test "brewfile_pending: a failed check that names no entry returns 2 with brew's output" {
  fake_brew_check 1 "Error: Invalid Brewfile: syntax errors found"
  run brewfile_pending "$BF"
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid Brewfile"* ]]
}
