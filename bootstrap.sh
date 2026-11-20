#!/bin/bash
# Set up a Mac from scratch (or re-check an existing one). Safe to re-run.
#
#   ./bootstrap.sh       ask before each step
#   ./bootstrap.sh -y    do every step without asking
#
# Fresh Mac:
#   xcode-select --install
#   git clone https://github.com/wwchen/dotfiles ~/code/wwchen/dotfiles
#   ~/code/wwchen/dotfiles/bootstrap.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YES=0
[[ "${1:-}" == "-y" || "${1:-}" == "--yes" ]] && YES=1
# Tells chezmoi run scripts (brew bundle) not to prompt either.
(( YES )) && export BOOTSTRAP_YES=1

bold=$'\e[1m'; yellow=$'\e[33m'; green=$'\e[32m'; red=$'\e[31m'; reset=$'\e[0m'
step() { echo; echo "${bold}==> $*${reset}"; }
ok()   { echo "${green}✓${reset} $*"; }
warn() { echo "${yellow}!${reset} $*"; }
die()  { echo "${red}✗ $*${reset}" >&2; exit 1; }

ask() {  # ask "question" -> 0 for yes (default), 1 for no
  (( YES )) && return 0
  local ans
  while true; do
    read -r -p "${yellow}$1?${reset} [Y/n] " ans </dev/tty
    case "${ans:-y}" in
      y|Y) return 0 ;;
      n|N) echo "  skipped"; return 1 ;;
    esac
  done
}

[[ "$(uname -s)" == "Darwin" ]] || die "bootstrap.sh is for macOS."

# 1. Command Line Tools (git, clang)
step "Xcode Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "installed"
elif ask "Install Command Line Tools"; then
  xcode-select --install || true
  echo "  Finish the installer window, then press return."
  read -r </dev/tty
fi

# 2. Homebrew
step "Homebrew"
if [[ -x /opt/homebrew/bin/brew ]]; then
  ok "installed"
elif ask "Install Homebrew"; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[[ -x /opt/homebrew/bin/brew ]] || die "Homebrew is required for the remaining steps."
eval "$(/opt/homebrew/bin/brew shellenv bash)"

# 3. chezmoi
step "chezmoi"
if command -v chezmoi >/dev/null; then
  ok "installed"
else
  brew install chezmoi
fi

# 4. Dotfiles (+ Brewfile, oh-my-zsh, iTerm2 via chezmoi run scripts)
step "Dotfiles, apps and iTerm2 (chezmoi)"
CZ=(chezmoi --source "$ROOT")   # always this checkout, even if chezmoi was set up from another
if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]]; then
  echo "  First run: chezmoi will ask for this machine's type (personal/work) and git email."
  chezmoi init --source "$ROOT"
elif [[ "$(chezmoi source-path 2>/dev/null)" != "$ROOT/home" ]]; then
  warn "chezmoi is set up from $(chezmoi source-path 2>/dev/null || echo '?'), not this checkout."
  if ask "Point chezmoi at $ROOT (keeps your machine type and email)"; then
    chezmoi init --source "$ROOT"
  fi
fi
changed="$("${CZ[@]}" status --exclude scripts,dirs | cut -c4-)"
if [[ -z "$changed" ]]; then
  ok "dotfiles already match the repo"
else
  echo "  These files in your home folder would change:"
  while IFS= read -r f; do echo "    ~/$f"; done <<<"$changed"
  if ask "Show the full diff"; then "${CZ[@]}" diff --exclude scripts; fi
fi
if ask "Apply dotfiles and install Brewfile apps (brew bundle asks again before installing)"; then
  "${CZ[@]}" apply
  ok "applied"
fi

# 5. Accounts that need a human
step "Sign-ins"
if command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1; then
  ask "Log in to GitHub CLI" && gh auth login
else
  ok "GitHub CLI logged in (or not installed yet)"
fi
# mas can't tell whether you're signed in any more ('mas account' was removed), so just remind.
echo "  App Store apps in the Brewfile install only when you're signed in to the App Store app."
echo "  If any were skipped, sign in and run 'just apply' (it retries only what's missing)."

echo
ok "Done. Day-to-day: 'just' lists the commands."
