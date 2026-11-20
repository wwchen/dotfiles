#!/bin/bash
# Bootstrap a fresh Mac: only what the rest of setup needs to run.
#
#   1. Homebrew          its installer also installs the Command Line Tools if they're missing
#   2. chezmoi, just, gh
#   3. Next steps        prints the commands to finish (gh login, clone this repo, `just apply`),
#                        leaving out what's already done. Bootstrap runs none of them.
#
# Safe to re-run: both installs leave what's already there alone.
#
#   curl -fsSL https://raw.githubusercontent.com/wwchen/dotfiles/master/bootstrap.sh | bash
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { echo "bootstrap.sh is for macOS." >&2; exit 1; }

GH_REPO="wwchen/dotfiles"
# By full path: on a fresh Mac, this script's PATH doesn't have Homebrew yet.
BREW=/opt/homebrew/bin/brew
bold=$'\e[1m'; reset=$'\e[0m'
step() { echo; echo "${bold}==> $*${reset}"; }

# Piped from curl, this script's own text is on stdin: give the installers the terminal
# instead (Homebrew's asks for your password), or nothing when there isn't one.
from_tty() { if { : </dev/tty; } 2>/dev/null; then "$@" </dev/tty; else "$@" </dev/null; fi; }

step "Homebrew"
from_tty /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

step "chezmoi, just, gh"
from_tty "$BREW" install chezmoi just gh

step "Next steps"
next=()
if [[ ":$PATH:" != *:/opt/homebrew/bin:* ]]; then
  # shellcheck disable=SC2016  # printed for you to run, not run here
  next+=('eval "$(/opt/homebrew/bin/brew shellenv)"')
fi
if ! /opt/homebrew/bin/gh auth status -h github.com >/dev/null 2>&1; then
  next+=("gh auth login -h github.com -p ssh -w")
fi
if [[ ! -f "$HOME/code/$GH_REPO/.chezmoiroot" ]]; then
  next+=("gh repo clone $GH_REPO ~/code/$GH_REPO")
fi
next+=("cd ~/code/$GH_REPO && just apply")

echo "To finish setting up this Mac, run:"
echo
printf '    %s\n' "${next[@]}"
echo
if [[ " ${next[*]} " == *" gh auth login "* ]]; then
  echo "gh auth login offers to make an SSH key and add it to GitHub, which the clone needs."
fi
echo "\`just apply\` shows what it would change and asks before changing anything."
