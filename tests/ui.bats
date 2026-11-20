#!/usr/bin/env bats
# Tests for scripts/ui.sh: UI_TTY is a file of typed answers; `gum` is a fake. Run: just test
bats_require_minimum_version 1.5.0

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  # shellcheck source=../scripts/ui.sh
  source "$ROOT/scripts/ui.sh"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  UI_TTY="$BATS_TEST_TMPDIR/tty"
  : > "$UI_TTY"   # a "terminal" with nothing typed yet
}

typed() { printf '%s\n' "$1" > "$UI_TTY"; }   # typed ANSWER -> what the plain prompt reads

# fake_gum STATUS [STDOUT]: gum's output and exit status; its arguments go to gum.log
fake_gum() {
  printf '%s' "${2:-}" > "$BATS_TEST_TMPDIR/gum.out"
  cat > "$BATS_TEST_TMPDIR/bin/gum" <<FAKE
#!/bin/bash
printf '%s\n' "\$*" >> "$BATS_TEST_TMPDIR/gum.log"
cat "$BATS_TEST_TMPDIR/gum.out"
exit $1
FAKE
  chmod +x "$BATS_TEST_TMPDIR/bin/gum"
}

# --- plain prompts (no gum, or UI_PLAIN=1)

@test "plain ui_confirm: Enter takes the default" {
  UI_PLAIN=1
  typed ""
  ui_confirm "Install?"
  run ui_confirm "Install?" no
  [ "$status" -eq 1 ]
}

@test "plain ui_confirm: y and n" {
  UI_PLAIN=1
  typed "n"; run ui_confirm "Install?"; [ "$status" -eq 1 ]
  typed "y"; run ui_confirm "Install?" no; [ "$status" -eq 0 ]
}

@test "plain ui_confirm: no terminal (or Ctrl-D) is no, even when the default is yes" {
  UI_PLAIN=1
  UI_TTY="$BATS_TEST_TMPDIR/no-such-tty"
  run ui_confirm "Install?"
  [ "$status" -eq 1 ]
  UI_TTY="$BATS_TEST_TMPDIR/tty"   # empty: Ctrl-D, end of input
  run ui_confirm "Install?"
  [ "$status" -eq 1 ]
}

@test "plain ui_choose: a number picks that option; Enter the default" {
  UI_PLAIN=1
  typed "2"
  [ "$(ui_choose "Pick" "skip" "add to Brewfile.apps" "ignore forever" "skip" 2>/dev/null)" = "ignore forever" ]
  typed ""
  [ "$(ui_choose "Pick" "skip" "add to Brewfile.apps" "ignore forever" "skip" 2>/dev/null)" = "skip" ]
}

@test "plain ui_choose: the menu goes to stderr, only the answer to stdout" {
  UI_PLAIN=1
  typed "1"
  run --separate-stderr ui_choose "Apply these changes?" "Cancel" "Apply" "Cancel"
  [ "$output" = "Apply" ]
  [[ "$stderr" == *"[1] Apply"* && "$stderr" == *"[2] Cancel (default)"* ]]
}

@test "without gum installed, the plain prompt is used" {
  rm -f "$BATS_TEST_TMPDIR/bin/gum"
  PATH="$BATS_TEST_TMPDIR/bin:/usr/bin:/bin"
  typed "n"
  run ui_confirm "Install?"
  [ "$status" -eq 1 ]
}

@test "UI_PLAIN=1 skips gum even when it's installed" {
  fake_gum 0
  UI_PLAIN=1
  typed "n"
  run ui_confirm "Install?"
  [ "$status" -eq 1 ]
  [ ! -e "$BATS_TEST_TMPDIR/gum.log" ]
}

# --- gum

@test "gum ui_confirm: yes/no from gum's exit status, default passed through" {
  fake_gum 0
  ui_confirm "Install?"
  fake_gum 1
  run ui_confirm "Install?" no
  [ "$status" -eq 1 ]
  [ "$(sed -n 1p "$BATS_TEST_TMPDIR/gum.log")" = "confirm --default=true Install?" ]
  [ "$(sed -n 2p "$BATS_TEST_TMPDIR/gum.log")" = "confirm --default=false Install?" ]
}

@test "gum ui_confirm: Ctrl-C stops the script" {
  fake_gum 130
  run env UI_TTY="$UI_TTY" PATH="$PATH" bash -c '. "$1"; ui_confirm "Install?"; echo "kept going"' _ "$ROOT/scripts/ui.sh"
  [ "$status" -eq 130 ]
  [[ "$output" != *"kept going"* ]]
}

@test "gum ui_choose: prints gum's choice, cursor starts on the default" {
  fake_gum 0 "Show file diff"
  [ "$(ui_choose "Apply these changes?" "Cancel" "Apply" "Show file diff" "Cancel")" = "Show file diff" ]
  [ "$(cat "$BATS_TEST_TMPDIR/gum.log")" = "choose --header Apply these changes? --selected Cancel Apply Show file diff Cancel" ]
}

@test "gum ui_choose: Esc takes the default; Ctrl-C returns 130" {
  fake_gum 1
  [ "$(ui_choose "Pick" "skip" "uninstall" "skip")" = "skip" ]
  fake_gum 130
  run ui_choose "Pick" "skip" "uninstall" "skip"
  [ "$status" -eq 130 ]
  [ -z "$output" ]
}
