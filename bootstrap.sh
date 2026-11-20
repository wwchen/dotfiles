#!/bin/bash
# Bootstrap a fresh Mac in three phases. Each phase asks before it starts, and every step
# checks first, so re-running only does what's still missing.
#
#   1. Prerequisites  Xcode Command Line Tools, Homebrew
#   2. Core apps      brew/Brewfile.core: every entry listed with ✓/+, then one question if any are missing
#   3. Setup          SSH key → GitHub (gh login, key added) → clone this repo over SSH
#                     → offer `just apply` (it shows its plan and asks before changing anything)
#
# Fresh Mac:
#   curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/bootstrap.sh | bash
# From a checkout (uses it; no clone):
#   ./bootstrap.sh       ask at each step
#   ./bootstrap.sh -y    don't ask   (piped: ... | bash -s -- -y)
#
# Overrides: DOTFILES_DIR  exact clone path (skips the code-root question)
#            DOTFILES_REF  branch the core Brewfile is read from without a checkout (master)
#            DOTFILES_REPO what to clone (git@github.com:wwchen/dotfiles.git)
set -euo pipefail

YES=0
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && YES=1
GH_REPO="wwchen/dotfiles"
REF="${DOTFILES_REF:-master}"
REPO_URL="${DOTFILES_REPO:-git@github.com:$GH_REPO.git}"
KEY="$HOME/.ssh/id_ed25519"
# Where the clone went, so re-runs reuse it instead of asking (and cloning) again.
CHECKOUT_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles/checkout"

bold=$'\e[1m'; blue=$'\e[34m'; yellow=$'\e[33m'; green=$'\e[32m'; red=$'\e[31m'; reset=$'\e[0m'
phase() { echo; echo "${bold}${blue}━━ $* ━━${reset}"; }
step()  { echo; echo "${bold}==> $*${reset}"; }
ok()    { echo "${green}✓${reset} $*"; }
warn()  { echo "${yellow}!${reset} $*"; }
die()   { echo "${red}✗ $*${reset}" >&2; exit 1; }

# Piped into bash, stdin is the script itself: questions (and interactive tools) use the terminal.
need_tty() { { : </dev/tty; } 2>/dev/null || die "No terminal to ask in; re-run with -y (piped: | bash -s -- -y)."; }

ask() {  # ask "question" -> 0 for yes (default), 1 for no
  (( YES )) && return 0
  need_tty
  local ans
  while true; do
    read -r -p "${yellow}$1?${reset} [Y/n] " ans </dev/tty
    case "${ans:-y}" in
      y|Y) return 0 ;;
      n|N) echo "  skipped"; return 1 ;;
    esac
  done
}

ask_value() {  # ask_value "question" default -> prints the answer (default with -y or Enter)
  local ans=""
  if (( ! YES )); then
    need_tty
    read -r -p "${yellow}$1${reset} [$2] " ans </dev/tty
  fi
  echo "${ans:-$2}"
}

abspath() {  # ~ and ~/x expand to the home folder; other relative paths are under it too
  local p="${1%/}"
  # shellcheck disable=SC2088  # matching a literal ~ typed by the user
  case "$p" in
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
    /*) ;;
    *) p="$HOME/$p" ;;
  esac
  echo "$p"
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
  echo "  Finish the installer window, then press return."
  read -r </dev/tty
fi
xcode-select -p >/dev/null 2>&1 || die "Command Line Tools are required (git); re-run once they're installed."

step "Homebrew"
if [[ -x /opt/homebrew/bin/brew ]]; then
  ok "installed"
elif ask "Install Homebrew"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
fi
[[ -x /opt/homebrew/bin/brew ]] || die "Homebrew is required for the remaining steps."
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
  # Every entry in the Brewfile, and which of them brew says are missing (it prints those on stderr).
  sed -nE 's/^[[:space:]]*(brew|cask|mas|tap|npm) "([^"]+)".*/\2/p' "$brewfile" > "$tmp/entries"
  brew bundle check --no-upgrade --verbose --file="$brewfile" 2>&1 \
    | sed -nE 's/^→ [A-Za-z]+ (.+) needs to be installed.*/\1/p' > "$tmp/missing" || true
  echo "  brew/Brewfile.core   (${green}✓${reset} installed, ${yellow}+${reset} to install)"
  col=0
  while IFS= read -r name; do
    if grep -qxF "$name" "$tmp/missing"; then mark="${yellow}+${reset}"; else mark="${green}✓${reset}"; fi
    (( col == 0 )) && printf '   '
    printf ' %s %-24s' "$mark" "$name"
    col=$(( (col + 1) % 3 )); (( col == 0 )) && echo
  done < "$tmp/entries"
  (( col == 0 )) || echo
  n_missing=$(wc -l < "$tmp/missing" | tr -d ' ')
  if (( n_missing == 0 )); then
    ok "all installed"
  elif ask "Install the $n_missing missing ($(paste -sd ',' "$tmp/missing" | sed 's/,/, /g'))"; then
    if HOMEBREW_CASK_OPTS="--adopt" brew bundle install --no-upgrade --file="$brewfile" </dev/tty; then
      ok "core apps installed"
    else
      warn "some failed; re-run to retry just those"
    fi
  fi
fi

# ════════════════════════════════════════════════════════════════════════════════════════
phase "3/3 Setup"
if ! ask "Continue to setup (SSH key, GitHub, clone this repo)"; then
  echo; ok "Stopped before setup. Re-run any time to continue."
  exit 0
fi

step "Tools for setup (gh, chezmoi, just)"
want=()
for t in gh chezmoi just; do command -v "$t" >/dev/null || want+=("$t"); done
if (( ${#want[@]} == 0 )); then
  ok "installed"
elif ask "Install ${want[*]}"; then
  brew install "${want[@]}"
fi
for t in gh chezmoi just; do command -v "$t" >/dev/null || die "$t is required for setup."; done

step "SSH key"
if [[ -f "$KEY" ]]; then
  ok "$KEY"
elif ask "Create an SSH key at $KEY (you'll pick a passphrase)"; then
  need_tty
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$(whoami)@$(scutil --get LocalHostName 2>/dev/null || hostname -s)" -f "$KEY" </dev/tty
fi
[[ -f "$KEY.pub" ]] || die "No SSH key; setup needs one to clone over SSH."
if ! grep -qs '^Host github.com' "$HOME/.ssh/config"; then
  # Keep the passphrase in the macOS keychain and load the key on first use.
  printf '\nHost github.com\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile %s\n' "$KEY" >> "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  ok "added a github.com entry to ~/.ssh/config"
fi

step "GitHub login"
if gh auth status -h github.com >/dev/null 2>&1; then
  ok "logged in"
elif ask "Log in to GitHub with gh (opens a browser)"; then
  need_tty
  gh auth login -h github.com -p ssh -w --skip-ssh-key -s admin:public_key </dev/tty
fi
gh auth status -h github.com >/dev/null 2>&1 || die "Setup needs a GitHub login to add the SSH key."

step "SSH key on GitHub"
pub="$(cut -d' ' -f1,2 "$KEY.pub")"
if gh api user/keys --jq '.[].key' 2>/dev/null | grep -qxF "$pub"; then
  ok "already added"
elif ask "Add $KEY.pub to your GitHub account"; then
  title="$(scutil --get ComputerName 2>/dev/null || hostname -s) ($(date +%F))"
  if ! gh ssh-key add "$KEY.pub" --title "$title" 2>/dev/null; then
    # Logged in without the scope to manage keys: ask for it, then retry once.
    need_tty
    gh auth refresh -h github.com -s admin:public_key </dev/tty
    gh ssh-key add "$KEY.pub" --title "$title"
  fi
  ok "added as \"$title\""
fi

step "dotfiles repo"
if [[ -n "$ROOT" ]]; then
  ok "using this checkout: $ROOT"
else
  remembered="$(cat "$CHECKOUT_FILE" 2>/dev/null || true)"
  if [[ -n "${DOTFILES_DIR:-}" ]]; then
    ROOT="$DOTFILES_DIR"
  elif [[ -n "$remembered" && -f "$remembered/.chezmoiroot" ]]; then
    ROOT="$remembered"
  else
    # shellcheck disable=SC2088  # shown to the user as-is, expanded by abspath
    ROOT="$(abspath "$(ask_value "Root folder for your code checkouts" "~/code")")/wwchen/dotfiles"
  fi
  if [[ -f "$ROOT/.chezmoiroot" ]]; then
    ok "at $ROOT"
  elif [[ -e "$ROOT" && -n "$(ls -A "$ROOT" 2>/dev/null)" ]]; then
    die "$ROOT exists but isn't this repo; set DOTFILES_DIR to clone somewhere else."
  elif ask "Clone $REPO_URL to $ROOT"; then
    mkdir -p "$(dirname "$ROOT")"
    # First connection to github.com: record its host key instead of prompting.
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new" git clone "$REPO_URL" "$ROOT"
  fi
  [[ -f "$ROOT/.chezmoiroot" ]] || die "The repo isn't at $ROOT; re-run to clone it."
  mkdir -p "$(dirname "$CHECKOUT_FILE")" && echo "$ROOT" > "$CHECKOUT_FILE"
fi

step "Set up this Mac"
if ask "Run just apply now (it shows the plan and asks before changing anything)"; then
  args=(); (( YES )) && args+=(-y)
  (cd "$ROOT" && just apply ${args[@]+"${args[@]}"})
else
  echo "  Later: cd $ROOT && just apply"
fi

echo
ok "Bootstrap done. Re-run any time; it only does what's missing."
