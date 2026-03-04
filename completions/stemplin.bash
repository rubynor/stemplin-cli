#!/usr/bin/env bash
# Bash/Zsh tab completion for the stemplin CLI.
# Source this file: source completions/stemplin.bash

_stemplin() {
  local cur prev commands
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  commands="me orgs clients projects tasks time users reports token update help"

  # Global flags
  if [[ "$cur" == -* ]]; then
    COMPREPLY=($(compgen -W "--raw --org --version --help" -- "$cur"))
    return
  fi

  # Find the subcommand (skip global flags)
  local cmd=""
  local i
  for ((i = 1; i < COMP_CWORD; i++)); do
    case "${COMP_WORDS[i]}" in
      --raw|--version|--help) ;;
      --org) ((i++)) ;;  # skip the org ID value
      -*) ;;
      *)
        cmd="${COMP_WORDS[i]}"
        break
        ;;
    esac
  done

  # Complete subcommand
  if [[ -z "$cmd" ]]; then
    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    return
  fi

  # Complete actions per subcommand
  case "$cmd" in
    orgs)     COMPREPLY=($(compgen -W "list show" -- "$cur")) ;;
    clients)  COMPREPLY=($(compgen -W "list show create update delete" -- "$cur")) ;;
    projects) COMPREPLY=($(compgen -W "list show create update delete" -- "$cur")) ;;
    tasks)    COMPREPLY=($(compgen -W "list show" -- "$cur")) ;;
    time)     COMPREPLY=($(compgen -W "list show create update delete timer" -- "$cur")) ;;
    users)    COMPREPLY=($(compgen -W "list show me" -- "$cur")) ;;
    reports)  COMPREPLY=($(compgen -W "show detailed" -- "$cur")) ;;
    token)    COMPREPLY=($(compgen -W "regenerate" -- "$cur")) ;;
    update)   COMPREPLY=($(compgen -W "--check" -- "$cur")) ;;
    help)     COMPREPLY=($(compgen -W "$commands" -- "$cur")) ;;
  esac

  # Complete flags per action
  local action=""
  for ((i = i + 1; i < COMP_CWORD; i++)); do
    case "${COMP_WORDS[i]}" in
      list|show|create|update|delete|timer|regenerate)
        action="${COMP_WORDS[i]}"
        break
        ;;
    esac
  done

  if [[ "$cur" == -* ]]; then
    case "$cmd" in
      time)
        case "$action" in
          list)   COMPREPLY=($(compgen -W "--date --from --to --project --per-page" -- "$cur")) ;;
          create) COMPREPLY=($(compgen -W "--task --minutes --date --notes" -- "$cur")) ;;
          update) COMPREPLY=($(compgen -W "--task --minutes --date --notes" -- "$cur")) ;;
        esac
        ;;
      clients)
        case "$action" in
          create|update) COMPREPLY=($(compgen -W "--name" -- "$cur")) ;;
        esac
        ;;
      projects)
        case "$action" in
          create|update) COMPREPLY=($(compgen -W "--name --client --rate --billable --desc --tasks" -- "$cur")) ;;
        esac
        ;;
      reports)
        COMPREPLY=($(compgen -W "--from --to --clients --projects --users --tasks" -- "$cur"))
        ;;
    esac
  fi
}

complete -F _stemplin stemplin
