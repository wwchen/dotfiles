#!/bin/bash
# Install Homebrew, then the Brewfiles in brew/, core first: list each one's packages, ask,
# and `brew bundle` it (installs what's missing, upgrades nothing).
#   curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/brew-install.sh | bash
#   ./brew-install.sh [-y] [group...]     -y: don't ask
set -euo pipefail

YES=0
groups=()
for arg in "$@"; do
  case "$arg" in
    -y|--yes) YES=1 ;;
    *) groups+=("$arg") ;;
  esac
done
trap 'echo; exit 130' INT
die() { echo "brew-install: $*" >&2; exit 1; }

find_brew() {  # puts Homebrew on PATH; fails if it isn't installed
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$b" ]]; then eval "$("$b" shellenv bash)"; return 0; fi
  done
  return 1
}
if ! find_brew; then
  echo "==> Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/tty
  find_brew || die "Homebrew didn't install (see above)."
fi

# brew/ from this checkout, or from GitHub when piped.
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
dir="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd)/brew"
if [[ ! -f "$dir/Brewfile.core" ]]; then
  curl -fsSL https://github.com/wwchen/dotfiles/archive/refs/heads/master.tar.gz |
    tar -xz -C "$tmp" --strip-components=1 dotfiles-master/brew
  dir="$tmp/brew"
fi

if (( ${#groups[@]} == 0 )); then
  groups=(core)
  for f in "$dir"/Brewfile.*; do [[ "$f" == */Brewfile.core ]] || groups+=("${f##*/Brewfile.}"); done
fi
for g in "${groups[@]}"; do [[ -f "$dir/Brewfile.$g" ]] || die "no brew/Brewfile.$g"; done

failed=()
for g in "${groups[@]}"; do
  file="$dir/Brewfile.$g"
  entries="$(grep -E '^[[:space:]]*(tap|brew|cask|mas|npm|vscode|go|cargo|uv) ' "$file" | sed 's/^[[:space:]]*//' || true)"
  [[ -n "$entries" ]] || continue
  echo
  echo "Brewfile.$g:"
  while IFS= read -r line; do echo "  $line"; done <<<"$entries"
  if (( ! YES )); then
    read -r -p "Install Brewfile.$g? [Y/n] " ans </dev/tty || ans=n
    if [[ "$ans" =~ ^[Nn] ]]; then echo "Skipped $g"; continue; fi
  fi
  echo "==> brew bundle ($g)"
  brew bundle install --no-upgrade --file="$file" || failed+=("$g")
done

if (( ${#failed[@]} )); then
  die "brew bundle failed for: ${failed[*]} (see above; App Store apps need you signed in). Run again to retry."
fi
