#!/usr/bin/env bats
# Unit tests for bootstrap.sh's own functions. Run: just test
# bootstrap.sh isn't run: its definitions (everything above the macOS check, where the real
# work starts) are loaded into the test. `brew` is a fake, first on PATH, whose
# `bundle check` output each test sets.

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  grep -q '^\[\[ "$(uname -s)" == "Darwin" \]\]' "$ROOT/bootstrap.sh" ||
    { echo "bootstrap.sh's macOS check moved: update how tests/bootstrap.bats loads it" >&2; return 1; }
  sed -n '/^set -euo pipefail$/d; /^\[\[ "$(uname -s)" == "Darwin" \]\]/q; p' "$ROOT/bootstrap.sh" \
    > "$BATS_TEST_TMPDIR/defs.sh"
  # shellcheck source=/dev/null
  source "$BATS_TEST_TMPDIR/defs.sh"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  BF="$BATS_TEST_TMPDIR/Brewfile"
  cat > "$BF" <<'BREWFILE'
# a comment
tap "hashicorp/tap"
brew "jq"
brew "jqp"
brew "libpq", link: true
cask "logi-options+"
  cask "iterm2"
mas "Some Thing Pro", id: 123
npm "prettier"
brew "jq"
BREWFILE
}

# fake_brew_check EXIT_STATUS [STDERR_TEXT] -> `brew bundle check` exits with that status,
# printing the text on stderr (where real brew prints what's missing)
fake_brew_check() {
  printf '%s\n' "${2:-}" > "$BATS_TEST_TMPDIR/check.out"
  cat > "$BATS_TEST_TMPDIR/bin/brew" <<FAKE
#!/bin/bash
[[ "\$1 \$2" == "bundle check" ]] || { echo "unexpected: brew \$*" >&2; exit 99; }
cat "$BATS_TEST_TMPDIR/check.out" >&2
exit $1
FAKE
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"
}

@test "abspath: empty and ~ are the home folder" {
  [ "$(abspath "")" = "$HOME" ]
  [ "$(abspath "~")" = "$HOME" ]
  [ "$(abspath "~/")" = "$HOME" ]
}

@test "abspath: ~/x and relative paths are under the home folder" {
  [ "$(abspath "~/code")" = "$HOME/code" ]
  [ "$(abspath "code/x")" = "$HOME/code/x" ]
}

@test "abspath: absolute paths are kept, minus a trailing slash" {
  [ "$(abspath "/opt/src/")" = "/opt/src" ]
  [ "$(abspath "/opt/src")" = "/opt/src" ]
}

@test "ask and ask_value: -y answers yes and takes the default without a terminal" {
  YES=1
  ask "Install things" </dev/null
  [ "$(ask_value "Root folder" "~/code" </dev/null)" = "~/code" ]
}

@test "brewfile_entries: names in file order; comments and options ignored, indented lines kept" {
  run brewfile_entries "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' hashicorp/tap jq jqp libpq logi-options+ iterm2 'Some Thing Pro' prettier jq)" ]
}

@test "brewfile_pending: nothing when brew bundle check passes" {
  fake_brew_check 0
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "brewfile_pending: formulae, casks and App Store apps to install" {
  fake_brew_check 1 "brew bundle can't satisfy your Brewfile's dependencies.
→ Formula jqp needs to be installed.
→ Cask iterm2 needs to be installed or updated.
→ App Some Thing Pro needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' jqp iterm2 'Some Thing Pro')" ]
}

@test "brewfile_pending: taps, link changes and npm packages count too" {
  fake_brew_check 1 "→ Tap hashicorp/tap needs to be tapped.
→ Formula libpq needs to be linked.
→ npm Package prettier needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' hashicorp/tap libpq prettier)" ]
}

@test "brewfile_pending: an entry listed twice is reported once" {
  fake_brew_check 1 "→ Formula jq needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "jq" ]
}

@test "brewfile_pending: a failed check that names no entry returns 2 with brew's output" {
  fake_brew_check 1 "Error: Invalid Brewfile: syntax errors found"
  run brewfile_pending "$BF"
  [ "$status" -eq 2 ]
  [[ "$output" == *"Invalid Brewfile"* ]]
}

@test "brewfile_show: ✓ for done, + for pending, every entry once per line it's on" {
  printf '%s\n' jqp iterm2 > "$BATS_TEST_TMPDIR/pending"
  run brewfile_show "$BF" "$BATS_TEST_TMPDIR/pending"
  [ "$status" -eq 0 ]
  plain="$(sed $'s/\e\\[[0-9;]*m//g' <<<"$output")"
  [[ "$plain" == *"+ jqp "* ]]
  [[ "$plain" == *"+ iterm2 "* ]]
  [[ "$plain" == *"✓ jq "* ]]
  [[ "$plain" == *"✓ Some Thing Pro "* ]]
  [ "${#lines[@]}" -eq 3 ]   # 9 entries, 3 columns
}
