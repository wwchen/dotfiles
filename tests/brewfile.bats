#!/usr/bin/env bats
# Tests for scripts/brewfile.sh, with a fake `brew`. Run: just test

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

# fake_brew_check STATUS [STDERR]: what `brew bundle check` exits with and prints
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

@test "brewfile_entries: names in file order, indented lines included" {
  run brewfile_entries "$BF"
  [ "${lines[0]}" = "hashicorp/tap" ]
  [ "${lines[3]}" = "logi-options+" ]
  [ "${lines[4]}" = "iterm2" ]
  [ "${lines[5]}" = "Some Thing Pro" ]
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
