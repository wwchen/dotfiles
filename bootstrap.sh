#!/bin/bash
# Bootstrap a fresh Mac in three phases. Each phase asks before it starts, and every step
# checks first, so re-running only does what's still missing.
#
#   1. Prerequisites  Xcode Command Line Tools, Homebrew
#   2. Core apps      brew/Brewfile.core: every entry listed with ✓/+, then one question if any are pending
#   3. Setup          SSH key → GitHub (gh login, key added) → clone this repo over SSH
#                     → offer `just apply` (it shows its plan and asks before changing anything)
#
# Fresh Mac:
#   curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/bootstrap.sh | bash
# From a checkout (uses it; no clone):
#   ./bootstrap.sh       ask at each step
#   ./bootstrap.sh -y    don't ask   (piped: ... | bash -s -- -y). Steps that are interactive by
#                        nature (passphrase, GitHub login) still need a terminal.
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

ask_value() {  # ask_value "question" default -> prints the answer (default with -y or Enter)
  local ans=""
  if (( ! YES )); then
    need_tty "Answering questions"
    read -r -p "${yellow}$1${reset} [$2] " ans </dev/tty || cancelled
  fi
  echo "${ans:-$2}"
}

abspath() {  # ~ and ~/x expand to the home folder; other relative paths are under it too
  local p="${1%/}"
  # shellcheck disable=SC2088  # matching a literal ~ typed by the user
  case "$p" in
    "") p="$HOME" ;;
    "~") p="$HOME" ;;
    "~/"*) p="$HOME/${p#\~/}" ;;
    /*) ;;
    *) p="$HOME/$p" ;;
  esac
  echo "$p"
}

# Brewfile helpers (the repo's scripts/brewfile.sh has the same ones; this script can't source
# it because it runs before the repo is cloned).
brewfile_entries() {  # brewfile_entries FILE -> each entry's name, one per line
  sed -nE 's/^[[:space:]]*(brew|cask|mas|tap|npm) "([^"]+)".*/\2/p' "$1"
}

brewfile_pending() {  # brewfile_pending FILE -> names of entries brew says need something
  # brew bundle check lists them on stderr, worded per kind: "→ Formula jq needs to be
  # installed.", "→ Tap x needs to be tapped.", "→ npm Package y needs to be installed.", ...
  # Matching each entry's own name copes with all of those. Returns 2 (with brew's output on
  # stderr) if the check failed but named none of the entries, e.g. a broken Brewfile.
  local out name found=0
  out="$(brew bundle check --no-upgrade --verbose --file="$1" 2>&1)" && return 0
  while IFS= read -r name; do
    if grep -qF " $name needs to be " <<<"$out"; then echo "$name"; found=1; fi
  done < <(brewfile_entries "$1")
  (( found )) && return 0
  echo "$out" >&2
  return 2
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
  brewfile_pending "$brewfile" > "$tmp/pending" 2> "$tmp/check-error" || status=$?
  echo "  brew/Brewfile.core   (${green}✓${reset} done, ${yellow}+${reset} to install/update)"
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
    (( status != 0 )) && what="brew bundle anyway"
    if ask "Install $what"; then
      if HOMEBREW_CASK_OPTS="--adopt" from_tty brew bundle install --no-upgrade --file="$brewfile"; then
        ok "core apps installed"
      else
        warn "some failed; re-run to retry just those"
      fi
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
if [[ -f "$KEY" && -f "$KEY.pub" ]]; then
  ok "$KEY"
elif [[ -f "$KEY" ]]; then
  # Private key without its .pub (e.g. restored from a backup): rebuild the public half.
  need_tty "Reading the key's passphrase"
  ssh-keygen -y -f "$KEY" </dev/tty > "$KEY.pub.tmp" && mv "$KEY.pub.tmp" "$KEY.pub"
  ok "rebuilt $KEY.pub from the private key"
elif ask "Create an SSH key at $KEY (you'll pick a passphrase)"; then
  need_tty "Creating an SSH key (passphrase)"
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  if [[ -f "$KEY.pub" ]]; then
    # A .pub without its private key is useless (and must not be uploaded): set it aside.
    mv "$KEY.pub" "$KEY.pub.orphaned-$(date +%Y%m%d%H%M%S)"
    warn "moved an orphaned $KEY.pub aside"
  fi
  ssh-keygen -t ed25519 -C "$(whoami)@$(scutil --get LocalHostName 2>/dev/null || hostname -s)" -f "$KEY" </dev/tty
fi
[[ -f "$KEY" && -f "$KEY.pub" ]] || die "No SSH key; setup needs one to clone over SSH."
# ssh -G shows the effective settings for github.com (Include, Match and aliases resolved).
if ssh -G github.com 2>/dev/null | grep -qx 'addkeystoagent true'; then
  ok "github.com is set up in ~/.ssh/config"
else
  # Keep the passphrase in the macOS keychain and load the key on first use.
  printf '\nHost github.com\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile %s\n' "$KEY" >> "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  ok "added a github.com entry to ~/.ssh/config"
fi

step "GitHub login"
if gh auth status -h github.com >/dev/null 2>&1; then
  :
elif ask "Log in to GitHub with gh (opens a browser)"; then
  need_tty "Logging in to GitHub"
  gh auth login -h github.com -p ssh -w --skip-ssh-key -s admin:public_key </dev/tty
fi
gh auth status -h github.com >/dev/null 2>&1 || die "Setup needs a GitHub login to add the SSH key."
login="$(gh api user --jq .login 2>/dev/null || echo '?')"
ok "logged in as $login"

step "SSH key on GitHub"
pub="$(cut -d' ' -f1,2 "$KEY.pub")"
if gh api user/keys --jq '.[].key' 2>/dev/null | grep -qxF "$pub"; then
  ok "already on $login's account"
elif ask "Add $KEY.pub to GitHub account $login"; then
  title="$(scutil --get ComputerName 2>/dev/null || hostname -s) ($(date +%F))"
  if ! err="$(gh ssh-key add "$KEY.pub" --title "$title" 2>&1)"; then
    if ! grep -qiE 'admin:public_key|scope|HTTP 404' <<<"$err"; then
      die "Couldn't add the key: $err"
    fi
    # Logged in without the scope to manage keys: ask for it, then retry once.
    if [[ -n "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]]; then
      die "The token in GH_TOKEN/GITHUB_TOKEN can't manage SSH keys (needs admin:public_key). Unset it, or add $KEY.pub on github.com yourself."
    fi
    need_tty "Granting gh the admin:public_key scope"
    gh auth refresh -h github.com -s admin:public_key </dev/tty
    gh ssh-key add "$KEY.pub" --title "$title"
  fi
  ok "added to $login as \"$title\""
fi

step "dotfiles repo"
if [[ -n "$ROOT" ]]; then
  ok "using this checkout: $ROOT"
else
  remembered="$(cat "$CHECKOUT_FILE" 2>/dev/null || true)"
  if [[ -n "${DOTFILES_DIR:-}" ]]; then
    ROOT="$(abspath "$DOTFILES_DIR")"
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
    if ! ssh-keygen -F github.com >/dev/null 2>&1; then
      # Pin GitHub's published host keys (fetched over HTTPS) instead of trusting whatever
      # answers the first SSH connection.
      mkdir -p "$HOME/.ssh"
      gh api meta --jq '.ssh_keys[] | "github.com " + .' >> "$HOME/.ssh/known_hosts" \
        || die "Couldn't fetch GitHub's SSH host keys."
      ok "added GitHub's SSH host keys to ~/.ssh/known_hosts"
    fi
    mkdir -p "$(dirname "$ROOT")"
    git clone "$REPO_URL" "$ROOT"
  fi
  [[ -f "$ROOT/.chezmoiroot" ]] || die "The repo isn't at $ROOT; re-run to clone it."
  mkdir -p "$(dirname "$CHECKOUT_FILE")" && echo "$ROOT" > "$CHECKOUT_FILE"
fi

step "Set up this Mac"
if ask "Run just apply now (it shows the plan and asks before changing anything)"; then
  args=(); (( YES )) && args+=(-y)
  (cd "$ROOT" && just apply ${args[@]+"${args[@]}"})
else
  echo "  Later: cd \"$ROOT\" && just apply"
fi

echo
ok "Bootstrap done. Re-run any time; it only does what's missing."
