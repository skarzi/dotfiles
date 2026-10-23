# shellcheck shell=bash

# Fills `COMPREPLY` from the word list `${1}` matching `${2}`.
_lumos_words() {
  COMPREPLY=()
  if [[ -z "${1}" ]]; then
    return 0
  fi
  mapfile -t COMPREPLY < <(compgen -W "${1}" -- "${2}" || true)
}

# Returns 0 when `${1}` appears in `COMP_WORDS` before the cursor.
_lumos_has_word() {
  local needle="${1}" index

  for ((index = 2; index < COMP_CWORD; index++)); do
    if [[ "${COMP_WORDS[index]}" == "${needle}" ]]; then
      return 0
    fi
  done
  return 1
}

# Offers `-d` and `--display` unless one is already present.
_complete_lumos_display_flag() {
  local options=""

  if ! _lumos_has_word "-d" && ! _lumos_has_word "--display"; then
    options="-d --display"
  fi
  _lumos_words "${options}" "${COMP_WORDS[COMP_CWORD]}"
}

_complete_lumos() {
  local subcommand="${COMP_WORDS[1]:-}" word="${COMP_WORDS[COMP_CWORD]}"
  local index options="" past_double_dash=false

  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    _lumos_words \
      "start adjust watch run stop status bedtime help -h --help" \
      "${word}"
    return 0
  fi

  case "${subcommand}" in
    start | watch)
      if [[ "${word}" == -* || "${COMP_CWORD}" -gt 2 ]]; then
        _complete_lumos_display_flag
      else
        COMPREPLY=()
      fi
      ;;
    run)
      for ((index = 2; index < COMP_CWORD; index++)); do
        if [[ "${COMP_WORDS[index]}" == "--" ]]; then
          past_double_dash=true
        fi
      done
      if [[ "${past_double_dash}" == true ]]; then
        mapfile -t COMPREPLY < <(compgen -c -- "${word}" || true)
        return 0
      fi
      options="--"
      if ! _lumos_has_word "-d" && ! _lumos_has_word "--display"; then
        options="-d --display --"
      fi
      _lumos_words "${options}" "${word}"
      ;;
    status)
      if _lumos_has_word "--short"; then
        COMPREPLY=()
      else
        _lumos_words "--short" "${word}"
      fi
      ;;
    *) COMPREPLY=() ;;
  esac
}

complete -F _complete_lumos lumos
