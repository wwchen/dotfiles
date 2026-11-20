#!/bin/bash
# Bootstrap a fresh Mac. Every step checks first, so re-running only does what's still missing.
#
#   1. Prerequisites  Xcode Command Line Tools, Homebrew
#   2. Core apps      brew/Brewfile.core: every entry listed with ✓/+, then one question if any are pending
#   3. Next steps     prints the commands to finish (gh login, clone this repo, `just apply`),
#                     leaving out what's already done. Bootstrap runs none of them.
#
# Fresh Mac:
#   curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/bootstrap.sh | bash
# From a checkout (uses it; no clone):
#   ./bootstrap.sh       ask at each step
#   ./bootstrap.sh -y    don't ask   (piped: ... | bash -s -- -y)
#
# Override: DOTFILES_REF  branch the core Brewfile is read from without a checkout (master)
set -euo pipefail

YES=0
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && YES=1
GH_REPO="wwchen/dotfiles"
REF="${DOTFILES_REF:-master}"

bold=$'\e[1m'; blue=$'\e[34m'; yellow=$'\e[33m'; green=$'\e[32m'; red=$'\e[31m'; reset=$'\e[0m'
phase() { echo; echo "${bold}${blue}━━ $* ━━${reset}"; }
step()  { echo; echo "${bold}==> $*${reset}"; }
ok()    { echo "${green}✓${reset} $*"; }
warn()  { echo "${yellow}!${reset} $*"; }
die()   { echo "${red}✗ $*${reset}" >&2; exit 1; }

# Piped into bash, stdin is the script itself: questions and interactive tools use the terminal.
has_tty() { { : </dev/tty; } 2>/dev/null; }
need_tty() {  # need_tty WHAT -> stop unless there's a terminal for WHAT
  has_tty && return 0
  if (( YES )); then die "$1 needs a terminal, even with -y. Run bootstrap in a terminal."; fi
  die "No terminal to ask in. Run bootstrap in a terminal, or with -y (piped: | bash -s -- -y)."
}
from_tty() {  # from_tty CMD... -> run CMD reading the terminal if there is one, else nothing
  if has_tty; then "$@" </dev/tty; else "$@" </dev/null; fi
}
cancelled() { echo; die "Cancelled. Re-run any time; it picks up where it left off."; }

ask() {  # ask "question" -> 0 for yes (default), 1 for no; Ctrl-D cancels
  (( YES )) && return 0
  need_tty "Answering questions"
  local ans
  while true; do
    read -r -p "${yellow}$1?${reset} [Y/n] " ans </dev/tty || cancelled
    case "${ans:-y}" in
      y|Y) return 0 ;;
      n|N) echo "  skipped"; return 1 ;;
    esac
  done
}

# Brewfile helpers. Kept in this file on purpose: bootstrap runs before the repo is cloned, so
# it can't load anything from it.
brewfile_entries() {  # brewfile_entries FILE -> each entry's name, one per line, in file order
  sed -nE 's/^[[:space:]]*(tap|brew|cask|mas|npm) "([^"]+)".*/\2/p' "$1"
}

brewfile_pending() {  # brewfile_pending FILE -> names of entries that need something
  # brew bundle check lists them on stderr, worded per kind: "→ Formula jq needs to be
  # installed.", "→ Tap x needs to be tapped.", "→ Formula libpq needs to be linked.",
  # "→ npm Package y needs to be installed.", ... Matching each entry's own name copes with all
  # of those. Entries already on this Mac outside Homebrew (brewfile_present) aren't pending.
  # Returns 2 (with brew's output on stderr) if the check failed but named none of the
  # entries, e.g. a broken Brewfile.
  local out type name key files="" found=0
  local flagged=() casks=()
  out="$(brew bundle check --no-upgrade --verbose --file="$1" 2>&1)" && return 0
  while read -r type name; do
    grep -qF " $name needs to be " <<<"$out" || continue
    found=1
    flagged+=("$type $name")
    if [[ "$type" == cask ]]; then casks+=("$name"); fi
  done < <(sed -nE 's/^[[:space:]]*(tap|brew|cask|mas|npm) "([^"]+)".*/\1 \2/p' "$1" | awk '!seen[$0]++')
  if (( ! found )); then
    echo "$out" >&2
    return 2
  fi
  # Look up every flagged cask in one brew call: each call spends a moment starting brew.
  if (( ${#casks[@]} )); then files="$(brewfile_cask_files "${casks[@]}")"; fi
  for key in "${flagged[@]}"; do
    brewfile_present "${key%% *}" "${key#* }" "$files" || echo "${key#* }"
  done
}

brewfile_present() {  # brewfile_present TYPE NAME [CASK_FILES] -> 0 if the entry is on this Mac without Homebrew
  # e.g. macOS's own /usr/bin/jq, or 1Password installed from its website. Formulae: a command
  # of that name on PATH. Casks: what the cask would install is all there (CASK_FILES, from
  # brewfile_cask_files; looked up if not given). App Store apps: /Applications/NAME.app.
  # Taps and npm packages: never.
  local cask kind file list found=0
  case "$1" in
    brew) type -P "${2##*/}" >/dev/null ;;
    mas) [[ -d "/Applications/$2.app" ]] ;;
    cask)
      if (( $# >= 3 )); then list="$3"; else list="$(brewfile_cask_files "$2")"; fi
      while read -r cask kind file; do
        [[ "$cask" == "$2" && -n "$kind" ]] || continue
        found=1
        case "$kind" in
          app) [[ -d "/Applications/$file" || -d "$HOME/Applications/$file" ]] || return 1 ;;
          binary) type -P "$file" >/dev/null || return 1 ;;
          font) [[ -f "$HOME/Library/Fonts/$file" || -f "/Library/Fonts/$file" ]] || return 1 ;;
        esac
      done <<<"$list"
      (( found )) ;;
    *) return 1 ;;
  esac
}

brewfile_cask_files() {  # brewfile_cask_files CASK... -> "<cask> <app|binary|font> <file name>" per file it installs
  # Only each cask's main kind: its apps if it has any, else its commands, else its fonts (so
  # a missing `code` command doesn't make a hand-installed VS Code pending). Nothing for a cask
  # brew doesn't know. Parsed with JavaScript for Automation: every Mac has it; jq may not be
  # there yet.
  local json c
  if ! json="$(brew info --cask --json=v2 "$@" 2>/dev/null)"; then
    # One unknown cask fails the whole call: look the others up one by one.
    if (( $# > 1 )); then for c in "$@"; do brewfile_cask_files "$c"; done; fi
    return 0
  fi
  osascript -l JavaScript -e '
    function run(argv) {
      var asked = argv.slice(1), out = [];
      (JSON.parse(argv[0]).casks || []).forEach(function (c) {
        var cask = asked.filter(function (n) { return n === c.token || n === c.full_token; })[0];
        if (!cask) return;
        var found = { app: [], binary: [], font: [] };
        (c.artifacts || []).forEach(function (a) {
          Object.keys(found).forEach(function (k) {
            if (!Array.isArray(a[k])) return;
            var opts = a[k].filter(function (x) { return x && typeof x === "object"; })[0] || {};
            var path = a.target || opts.target || a[k].filter(function (x) { return typeof x === "string"; })[0];
            if (!path) return;
            // Apps keep their folder under /Applications (e.g. "Adobe X/X.app"); others by name.
            var name = k === "app" && path.indexOf("/Applications/") === 0
              ? path.slice("/Applications/".length) : path.split("/").pop();
            found[k].push(cask + " " + k + " " + name);
          });
        });
        out = out.concat(found.app.length ? found.app : found.binary.length ? found.binary : found.font);
      });
      return out.join("\n");
    }' "$json" "$@" 2>/dev/null
}

brewfile_select() {  # brewfile_select FILE NAMES_FILE -> FILE's entry lines (options kept) for those names
  # The Brewfile to install from when only some entries are pending.
  awk 'FILENAME == ARGV[1] { want[$0] = 1; next }
       match($0, /^[[:space:]]*(tap|brew|cask|mas|npm) "[^"]+"/) {
         name = substr($0, RSTART, RLENGTH); sub(/^[^"]*"/, "", name); sub(/"$/, "", name)
         if ((name in want) && !seen[$0]++) print
       }' "$2" "$1"
}

brewfile_show() {  # brewfile_show FILE PENDING_LIST -> every entry in 3 columns, ✓ done / + pending
  local name mark col=0
  while IFS= read -r name; do
    if grep -qxF "$name" "$2"; then mark="${yellow}+${reset}"; else mark="${green}✓${reset}"; fi
    (( col == 0 )) && printf '   '
    printf ' %s %-24s' "$mark" "$name"
    col=$(( (col + 1) % 3 )); (( col == 0 )) && echo
  done < <(brewfile_entries "$1")
  (( col == 0 )) || echo
}

[[ "$(uname -s)" == "Darwin" ]] || die "bootstrap.sh is for macOS."

# Running from a checkout (./bootstrap.sh) or piped from curl (no checkout yet)?
SELF="${BASH_SOURCE[0]:-}"
ROOT=""
if [[ -n "$SELF" && -f "$SELF" && -f "$(dirname "$SELF")/.chezmoiroot" ]]; then
  ROOT="$(cd "$(dirname "$SELF")" && pwd)"
fi
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
# Ctrl-C stops everything. Without this, a tool that catches Ctrl-C itself (brew does) just
# exits with an error, and the script would carry on to the next step.
trap 'echo; echo "${red}✗ Interrupted.${reset} Re-run any time; it picks up where it left off." >&2; exit 130' INT

# ════════════════════════════════════════════════════════════════════════════════════════
phase "1/3 Prerequisites"

step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "installed"
elif ask "Install Command Line Tools"; then
  xcode-select --install || true
  need_tty "Waiting for the Command Line Tools installer"
  echo "  Finish the installer window, then press return."
  read -r </dev/tty || cancelled
fi
xcode-select -p >/dev/null 2>&1 || die "Command Line Tools are required (git); re-run once they're installed."

step "Homebrew"
if [[ -x /opt/homebrew/bin/brew ]]; then
  ok "installed"
elif ask "Install Homebrew"; then
  from_tty /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[[ -x /opt/homebrew/bin/brew ]] || die "Homebrew is required for the remaining steps (Apple Silicon: /opt/homebrew)."
case ":$PATH:" in
  *:/opt/homebrew/bin:*) ;;
  *) eval "$(/opt/homebrew/bin/brew shellenv bash)" ;;
esac

# ════════════════════════════════════════════════════════════════════════════════════════
phase "2/3 Core apps"
if [[ -n "$ROOT" ]]; then
  brewfile="$ROOT/brew/Brewfile.core"
else
  brewfile="$tmp/Brewfile.core"
  curl -fsSL "https://raw.githubusercontent.com/$GH_REPO/$REF/brew/Brewfile.core" -o "$brewfile" 2>/dev/null || brewfile=""
fi
if [[ -z "$brewfile" || ! -f "$brewfile" ]]; then
  warn "no brew/Brewfile.core on $REF; skipping core apps"
else
  status=0
  echo "  brew/Brewfile.core   (${green}✓${reset} done, ${yellow}+${reset} to install/update)"
  # brew takes a few seconds to check; say so, then clear the line once it's done.
  if [[ -t 1 ]]; then printf '    checking what is installed...'; fi
  brewfile_pending "$brewfile" > "$tmp/pending" 2> "$tmp/check-error" || status=$?
  if [[ -t 1 ]]; then printf '\r\033[K'; fi
  brewfile_show "$brewfile" "$tmp/pending"
  n_pending=$(wc -l < "$tmp/pending" | tr -d ' ')
  if (( status != 0 )); then
    warn "brew bundle check failed without naming an entry:"
    sed 's/^/    /' "$tmp/check-error"
  elif (( n_pending == 0 )); then
    ok "all installed"
  fi
  if (( status != 0 || n_pending > 0 )); then
    what="the $n_pending pending ($(paste -sd ',' "$tmp/pending" | sed 's/,/, /g'))"
    # Only the pending entries: the rest are installed, some of them without Homebrew, and
    # brew would install those again (or fail to --adopt an app that isn't the same version).
    brewfile_select "$brewfile" "$tmp/pending" > "$tmp/Brewfile.pending"
    install_from="$tmp/Brewfile.pending"
    if (( status != 0 )); then what="brew bundle anyway"; install_from="$brewfile"; fi
    if ask "Install $what"; then
      if HOMEBREW_CASK_OPTS="--adopt" from_tty brew bundle install --no-upgrade --file="$install_from"; then
        ok "core apps installed"
      else
        warn "some failed; re-run to retry just those"
      fi
    fi
  fi
fi

# ════════════════════════════════════════════════════════════════════════════════════════
phase "3/3 Next steps"
# Bootstrap stops here: the rest is printed for you to run, minus what's already done.
# (gh, chezmoi and just come with the core apps in phase 2.)
next=()
if ! { command -v gh >/dev/null && gh auth status -h github.com >/dev/null 2>&1; }; then
  next+=("gh auth login -h github.com -p ssh -w")
fi
# This checkout if bootstrap runs from one, else ~/code/wwchen/dotfiles (clone it anywhere).
dir="${ROOT:-$HOME/code/$GH_REPO}"
shown="$(printf '%q' "$dir")"
if [[ "$dir" == "$HOME/"* ]]; then
  # shellcheck disable=SC2088  # a literal ~ for you to paste; your shell expands it
  shown="~/$(printf '%q' "${dir#"$HOME/"}")"
fi
if [[ ! -f "$dir/.chezmoiroot" ]]; then
  next+=("git clone git@github.com:$GH_REPO.git $shown")
fi
next+=("cd $shown && just apply")

echo "  To finish setting up this Mac, run:"
echo
printf '    %s\n' "${next[@]}"
echo
echo "  Cloning over SSH needs your SSH key on GitHub: gh auth login offers to make and add one."
echo "  \`just apply\` shows what it would change and asks before changing anything."
echo
ok "Bootstrap done. Re-run any time; it only does what's missing."
