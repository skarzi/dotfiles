# shellcheck shell=bash

_complete_display_light() {
  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    mapfile -t COMPREPLY < <(
      compgen -W "toggle get set" -- "${COMP_WORDS[COMP_CWORD]}" || true
    )
    return 0
  fi
  COMPREPLY=()
}

complete -F _complete_display_light display_light
