#!/bin/bash
# Bootstrap a fresh Mac in three phases. Each phase asks before it starts, and every step
# checks first, so re-running only does what's still missing.
#
#   1. Prerequisites  Xcode Command Line Tools, Homebrew
#   2. Core apps      brew/Brewfile.core: every entry listed with ✓/+, then one question if any are pending
#   3. Setup          SSH key and GitHub checks (gh login; key creation and upload are shown
#                     as commands for you to run) → clone this repo over SSH
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
  local out type name found=0
  out="$(brew bundle check --no-upgrade --verbose --file="$1" 2>&1)" && return 0
  while read -r type name; do
    grep -qF " $name needs to be " <<<"$out" || continue
    found=1
    brewfile_present "$type" "$name" || echo "$name"
  done < <(sed -nE 's/^[[:space:]]*(tap|brew|cask|mas|npm) "([^"]+)".*/\1 \2/p' "$1" | awk '!seen[$0]++')
  (( found )) && return 0
  echo "$out" >&2
  return 2
}

brewfile_present() {  # brewfile_present TYPE NAME -> 0 if the entry is on this Mac without Homebrew
  # e.g. macOS's own /usr/bin/jq, or 1Password installed from its website. Formulae: a command
  # of that name on PATH. Casks: what the cask would install (brewfile_cask_files) is all there.
  # App Store apps: /Applications/NAME.app. Taps and npm packages: never.
  local kind file found=0
  case "$1" in
    brew) type -P "${2##*/}" >/dev/null ;;
    mas) [[ -d "/Applications/$2.app" ]] ;;
    cask)
      while read -r kind file; do
        [[ -n "$kind" ]] || continue
        found=1
        case "$kind" in
          app) [[ -d "/Applications/$file" || -d "$HOME/Applications/$file" ]] || return 1 ;;
          binary) type -P "$file" >/dev/null || return 1 ;;
          font) [[ -f "$HOME/Library/Fonts/$file" || -f "/Library/Fonts/$file" ]] || return 1 ;;
        esac
      done < <(brewfile_cask_files "$2")
      (( found )) ;;
    *) return 1 ;;
  esac
}

brewfile_cask_files() {  # brewfile_cask_files CASK -> "<app|binary|font> <file name>" per file it installs
  # Only its main kind: its apps if it has any, else its commands, else its fonts (so a missing
  # `code` command doesn't make a hand-installed VS Code pending). Nothing if brew doesn't know
  # the cask. Parsed with JavaScript for Automation: every Mac has it; jq may not be there yet.
  local json
  json="$(brew info --cask --json=v2 "$1" 2>/dev/null)" || return 0
  osascript -l JavaScript -e '
    function run(argv) {
      var found = { app: [], binary: [], font: [] };
      (JSON.parse(argv[0]).casks || []).forEach(function (c) {
        (c.artifacts || []).forEach(function (a) {
          Object.keys(found).forEach(function (k) {
            if (!Array.isArray(a[k])) return;
            var opts = a[k].filter(function (x) { return x && typeof x === "object"; })[0] || {};
            var path = a.target || opts.target || a[k].filter(function (x) { return typeof x === "string"; })[0];
            if (!path) return;
            // Apps keep their folder under /Applications (e.g. "Adobe X/X.app"); others by name.
            var name = k === "app" && path.indexOf("/Applications/") === 0
              ? path.slice("/Applications/".length) : path.split("/").pop();
            found[k].push(k + " " + name);
          });
        });
      });
      return (found.app.length ? found.app : found.binary.length ? found.binary : found.font).join("\n");
    }' "$json" 2>/dev/null
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

# SSH: bootstrap only checks. It never creates a key or adds one to GitHub; it prints the
# commands to do that (repeated at the end), and you re-run it afterwards.
TODO=()
todo() { TODO+=("$1"); echo "    ${bold}$1${reset}"; }  # todo CMD -> show CMD to run, and remember it
q() {  # q STRING -> STRING quoted for pasting into a shell (only if it needs it)
  local sq="'"
  if [[ "$1" =~ ^[A-Za-z0-9_./:@%+=-]+$ ]]; then echo "$1"; else echo "'${1//$sq/$sq\\$sq$sq}'"; fi
}

step "SSH key"
# ssh -G shows the effective settings for github.com (Include, Match and aliases resolved).
ssh_github="$(ssh -G github.com 2>/dev/null || true)"
# The agent ssh uses for github.com (IdentityAgent, e.g. 1Password's, else SSH_AUTH_SOCK), and
# the public keys it holds: those count as much as a key file.
agent="$(sed -n 's/^identityagent //p' <<<"$ssh_github" | head -1)"
case "$agent" in "" | SSH_AUTH_SOCK) agent="${SSH_AUTH_SOCK:-}" ;; none) agent="" ;; esac
agent_keys=""
[[ -n "$agent" ]] && agent_keys="$(SSH_AUTH_SOCK="$agent" ssh-add -L 2>/dev/null | grep '^ssh-' || true)"
key_cmd="ssh-keygen -t ed25519 -C $(q "$(whoami)@$(scutil --get LocalHostName 2>/dev/null || hostname -s)") -f $(q "$KEY")"
if [[ -f "$KEY" && -f "$KEY.pub" ]]; then
  ok "$KEY"
elif [[ -f "$KEY" ]]; then
  warn "$KEY has no .pub next to it. To rebuild it from the private key:"
  todo "ssh-keygen -y -f $(q "$KEY") > $(q "$KEY.pub")"
elif [[ -n "$agent_keys" ]]; then
  ok "no $KEY; the SSH agent has $(grep -c . <<<"$agent_keys") key(s)"
else
  warn "no SSH key. To create one (it asks for a passphrase):"
  todo "$key_cmd"
fi
# Keep a key file's passphrase in the macOS keychain. Leave ~/.ssh/config alone if it already
# handles github.com: keys loaded into the agent, another agent serving the keys
# (IdentityAgent), or a Host entry for it. The last check also keeps re-runs from appending
# again when an earlier block (Host *) overrides AddKeysToAgent: ssh uses the first value.
if [[ -f "$KEY" ]]; then
  if grep -qx 'addkeystoagent true' <<<"$ssh_github"; then
    ok "github.com is set up in ~/.ssh/config"
  elif [[ -n "$agent" && "$agent" != "${SSH_AUTH_SOCK:-}" ]]; then
    ok "github.com keys come from an SSH agent ($agent); ~/.ssh/config left as is"
  elif grep -qiE '^[[:space:]]*Host[[:space:]]+(.*[[:space:]])?github\.com([[:space:]]|$)' "$HOME/.ssh/config" 2>/dev/null; then
    ok "github.com already has an entry in ~/.ssh/config"
  else
    printf '\nHost github.com\n  AddKeysToAgent yes\n  UseKeychain yes\n  IdentityFile %s\n' "$KEY" >> "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    ok "added a github.com entry to ~/.ssh/config"
  fi
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
# users/LOGIN/keys is public: user/keys would need a token scope (read:public_key) that a
# plain `gh auth login` doesn't grant, and a failed read looks like "not added".
ssh_ok=0
mine="$( { [[ -f "$KEY" && -f "$KEY.pub" ]] && cat "$KEY.pub"; printf '%s\n' "$agent_keys"; } | cut -d' ' -f1,2 | grep '^ssh-' || true)"
if ! gh_keys="$(gh api "users/$login/keys" --jq '.[].key' 2>/dev/null)"; then
  warn "couldn't read $login's SSH keys from GitHub; check https://github.com/settings/keys"
elif [[ -n "$mine" && -n "$gh_keys" ]] && match="$(grep -xFf <(printf '%s\n' "$gh_keys") <<<"$mine" | head -1)"; then
  ssh_ok=1
  if [[ -f "$KEY.pub" && "$(cut -d' ' -f1,2 "$KEY.pub")" == "$match" ]]; then
    ok "$KEY.pub is on $login's account"
  else
    ok "a key from the SSH agent is on $login's account"
  fi
else
  if [[ -f "$KEY.pub" ]]; then
    warn "$KEY.pub isn't on $login's GitHub account. To add it:"
  else
    warn "no SSH key of yours is on $login's GitHub account. Once $KEY.pub exists, to add it:"
    # The agent's keys aren't on GitHub either: a key file is the way forward.
    if [[ -n "$agent_keys" && ! -f "$KEY" ]]; then todo "$key_cmd"; fi
  fi
  # gh needs the admin:public_key scope to add keys; a token without it gets it here.
  if ! gh auth status -h github.com 2>&1 | grep -qE "Token scopes:.*'(admin|write):public_key'"; then
    todo "gh auth refresh -h github.com -s admin:public_key"
  fi
  todo "gh ssh-key add $(q "$KEY.pub") --title $(q "$(scutil --get ComputerName 2>/dev/null || hostname -s)")"
fi

show_todo() {  # what's left for you to run, then re-run bootstrap
  (( ${#TODO[@]} )) || return 0
  echo
  echo "${yellow}To finish, run these, then re-run bootstrap:${reset}"
  printf '    %s\n' "${TODO[@]}"
}

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
  elif (( ! ssh_ok )); then
    warn "cloning $REPO_URL needs your SSH key on GitHub; stopping here"
    show_todo
    exit 0
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
show_todo
