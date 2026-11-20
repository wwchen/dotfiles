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
# printing the text on stderr (where real brew prints what's missing). `brew info --cask
# --json=v2 NAME` prints $BATS_TEST_TMPDIR/casks/NAME.json, or fails like an unknown cask.
fake_brew_check() {
  printf '%s\n' "${2:-}" > "$BATS_TEST_TMPDIR/check.out"
  mkdir -p "$BATS_TEST_TMPDIR/casks"
  cat > "$BATS_TEST_TMPDIR/bin/brew" <<FAKE
#!/bin/bash
case "\$1 \$2" in
  "bundle check") cat "$BATS_TEST_TMPDIR/check.out" >&2; exit $1 ;;
  "info --cask") cat "$BATS_TEST_TMPDIR/casks/\$4.json" 2>/dev/null || { echo "Error: No available cask" >&2; exit 1; } ;;
  *) echo "unexpected: brew \$*" >&2; exit 99 ;;
esac
FAKE
  chmod +x "$BATS_TEST_TMPDIR/bin/brew"
}

# only_present "TYPE NAME"... -> brewfile_pending sees just these as already on this Mac
# (the real brewfile_present looks at this Mac: /usr/bin/jq would count). No args: none.
only_present() {
  printf '%s\n' "$@" > "$BATS_TEST_TMPDIR/present"
  brewfile_present() { grep -qxF "$1 $2" "$BATS_TEST_TMPDIR/present"; }
}

# fake_cask NAME JSON_ARTIFACTS -> what `brew info --cask --json=v2 NAME` reports it installs
fake_cask() { printf '{"casks":[{"token":"%s","artifacts":%s}]}\n' "$1" "$2" > "$BATS_TEST_TMPDIR/casks/$1.json"; }

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
  only_present
  fake_brew_check 1 "brew bundle can't satisfy your Brewfile's dependencies.
→ Formula jqp needs to be installed.
→ Cask iterm2 needs to be installed or updated.
→ App Some Thing Pro needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' jqp iterm2 'Some Thing Pro')" ]
}

@test "brewfile_pending: taps, link changes and npm packages count too" {
  only_present
  fake_brew_check 1 "→ Tap hashicorp/tap needs to be tapped.
→ Formula libpq needs to be linked.
→ npm Package prettier needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' hashicorp/tap libpq prettier)" ]
}

@test "brewfile_pending: an entry listed twice is reported once" {
  only_present
  fake_brew_check 1 "→ Formula jq needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "jq" ]
}

@test "brewfile_pending: entries already on this Mac outside Homebrew aren't pending" {
  only_present "brew jq" "cask iterm2"
  fake_brew_check 1 "→ Formula jq needs to be installed.
→ Formula jqp needs to be installed.
→ Cask iterm2 needs to be installed or updated."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ "$output" = "jqp" ]
}

@test "brewfile_pending: all of them already on this Mac is nothing pending, not a failure" {
  only_present "brew jq"
  fake_brew_check 1 "→ Formula jq needs to be installed."
  run brewfile_pending "$BF"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
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

@test "brewfile_present: a formula counts if a command of its name is on PATH, tap prefix ignored" {
  fake_brew_check 0
  printf '#!/bin/sh\n' > "$BATS_TEST_TMPDIR/bin/fakeformula"
  chmod +x "$BATS_TEST_TMPDIR/bin/fakeformula"
  brewfile_present brew fakeformula
  brewfile_present brew some/tap/fakeformula
  run brewfile_present brew no-such-formula-here
  [ "$status" -ne 0 ]
}

@test "brewfile_present: taps, npm packages and missing App Store apps never count" {
  run brewfile_present tap hashicorp/tap
  [ "$status" -ne 0 ]
  run brewfile_present npm prettier
  [ "$status" -ne 0 ]
  run brewfile_present mas "No Such App Anywhere"
  [ "$status" -ne 0 ]
}

@test "brewfile_present: a cask counts when its app is in ~/Applications" {
  fake_brew_check 0
  HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/Applications/Fake Thing.app"
  fake_cask fake-thing '[{"app":["Fake Thing.app"]},{"binary":["$APPDIR/Fake Thing.app/Contents/bin/fake",{"target":"fake-thing-cli"}]}]'
  fake_cask other-thing '[{"app":["Other Thing.app"]}]'
  brewfile_present cask fake-thing   # its app is there; its missing command doesn't matter
  run brewfile_present cask other-thing
  [ "$status" -ne 0 ]
}

@test "brewfile_present: a cask brew doesn't know never counts" {
  fake_brew_check 0
  run brewfile_present cask no-such-cask
  [ "$status" -ne 0 ]
}

@test "brewfile_cask_files: apps first (folder under /Applications kept), else commands, else fonts" {
  fake_brew_check 0
  fake_cask suite '[{"app":["Suite.app",{"target":"/Applications/Vendor Suite/Suite.app"}]},{"binary":["bin/suite"]}]'
  fake_cask cli '[{"binary":["$APPDIR/X.app/Contents/bin/x",{"target":"x-cli"}]}]'
  fake_cask font-thing '[{"font":["Thing-Regular.ttf"]}]'
  [ "$(brewfile_cask_files suite)" = "app Vendor Suite/Suite.app" ]
  [ "$(brewfile_cask_files cli)" = "binary x-cli" ]
  [ "$(brewfile_cask_files font-thing)" = "font Thing-Regular.ttf" ]
  [ -z "$(brewfile_cask_files no-such-cask)" ]
}

@test "brewfile_select: the full lines for those names, options kept, each once" {
  printf '%s\n' jq libpq 'Some Thing Pro' > "$BATS_TEST_TMPDIR/names"
  run brewfile_select "$BF" "$BATS_TEST_TMPDIR/names"
  [ "$status" -eq 0 ]
  [ "$output" = "$(printf '%s\n' 'brew "jq"' 'brew "libpq", link: true' 'mas "Some Thing Pro", id: 123')" ]
}
