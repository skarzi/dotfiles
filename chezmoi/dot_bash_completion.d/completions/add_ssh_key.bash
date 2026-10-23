# shellcheck shell=bash

# Completes `add_ssh_key` with private key names under `~/.ssh`.
_complete_add_ssh_key() {
  local ssh_directory="${HOME}/.ssh" key name
  local -a names=()

  COMPREPLY=()
  if [[ "${COMP_CWORD}" -ne 1 || ! -d "${ssh_directory}" ]]; then
    return 0
  fi
  for key in "${ssh_directory}"/*; do
    [[ -f "${key}" ]] || continue
    name="${key##*/}"
    case "${name}" in
      *.pub | config | known_hosts | known_hosts.old | \
        authorized_keys | authorized_keys2)
        continue
        ;;
    esac
    names+=("${name}")
  done
  if ((${#names[@]} > 0)); then
    mapfile -t COMPREPLY < <(
      compgen -W "${names[*]}" -- "${COMP_WORDS[COMP_CWORD]}" || true
    )
  fi
}

complete -F _complete_add_ssh_key add_ssh_key
