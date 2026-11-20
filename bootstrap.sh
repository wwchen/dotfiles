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
if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]]; then
  echo "  First run: chezmoi will ask for this machine's type (personal/work) and git email."
  chezmoi init --source "$ROOT"
fi
if chezmoi diff --exclude scripts --no-pager >/dev/null 2>&1 && [[ -z "$(chezmoi diff --exclude scripts --no-pager)" ]]; then
  ok "dotfiles already match the repo"
else
  echo "  These files in your home folder would change:"
  chezmoi diff --exclude scripts --no-pager | grep -E '^diff --git' | sed -E 's#^diff --git a/([^ ]+).*#    ~/\1#' || true
  if ask "Show the full diff"; then chezmoi diff --exclude scripts; fi
fi
if ask "Apply dotfiles and install Brewfile apps (brew bundle asks again before installing)"; then
  chezmoi apply
  ok "applied"
fi

# 5. Accounts that need a human
step "Sign-ins"
if command -v gh >/dev/null && ! gh auth status >/dev/null 2>&1; then
  ask "Log in to GitHub CLI" && gh auth login
else
  ok "GitHub CLI logged in (or not installed yet)"
fi
if command -v mas >/dev/null && ! mas account >/dev/null 2>&1; then
  warn "Sign in to the App Store app, then re-run so 'mas' apps install."
fi

echo
ok "Done. Day-to-day: 'just' lists the commands."
