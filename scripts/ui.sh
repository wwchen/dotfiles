# shellcheck shell=bash
# Prompts (sourced): gum on a terminal, else plain `read` (or UI_PLAIN=1). Read the terminal,
# not stdin. Enter/Esc: default. No terminal: confirm says no. Ctrl-C: exit 130.
#   ui_confirm QUESTION [yes|no]         0 = yes (default yes)
#   ui_choose HEADER DEFAULT OPTION...   prints the choice; call as x="$(ui_choose ...)" || exit $?

UI_TTY="${UI_TTY:-/dev/tty}"   # tests point this at a file of answers

ui_tty() { { : <"$UI_TTY"; } 2>/dev/null; }   # is there a terminal to ask in?
ui_gum() { [[ -z "${UI_PLAIN:-}" ]] && command -v gum >/dev/null && ui_tty; }

ui_confirm() {
  local question="$1" default="${2:-yes}" ans rc
  if ui_gum; then
    rc=0
    gum confirm --default="$([[ "$default" == yes ]] && echo true || echo false)" \
      "$question" <"$UI_TTY" || rc=$?
    (( rc == 130 )) && exit 130
    return $(( rc == 0 ? 0 : 1 ))
  fi
  local hint="[Y/n]"; [[ "$default" == yes ]] || hint="[y/N]"
  read -r -p "$question $hint " ans <"$UI_TTY" || { echo; return 1; }
  case "${ans:-$default}" in
    y|Y|yes|Yes) return 0 ;;
    *) return 1 ;;
  esac
}

ui_choose() {
  local header="$1" default="$2" ans rc i
  shift 2
  if ui_gum; then
    rc=0
    ans="$(gum choose --header "$header" --selected "$default" "$@" <"$UI_TTY")" || rc=$?
    (( rc == 130 )) && return 130
    echo "${ans:-$default}"   # Esc: the default
    return 0
  fi
  echo "$header" >&2
  for (( i = 1; i <= $#; i++ )); do
    printf '  [%d] %s%s\n' "$i" "${!i}" "$([[ "${!i}" == "$default" ]] && echo " (default)")" >&2
  done
  while true; do
    read -r -p "  [1-$#, Enter = $default] " ans <"$UI_TTY" || ans=""
    if [[ -z "$ans" ]]; then echo "$default"; return 0; fi
    if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= $# )); then echo "${!ans}"; return 0; fi
  done
}
