#compdef stemplin
# Zsh completion for the stemplin CLI.
# Install: copy to a directory in your $fpath, e.g.:
#   cp completions/stemplin.zsh ~/.local/share/zsh/site-functions/_stemplin

local -a commands
commands=(
  'me:Show your profile'
  'orgs:Organizations'
  'clients:Clients'
  'projects:Projects'
  'tasks:Tasks'
  'time:Time entries'
  'users:Users'
  'reports:Reports'
  'token:API token management'
  'help:Show help'
)

_stemplin_global_flags() {
  _arguments -S \
    '--raw[Output raw JSON]' \
    '--org[Set organization ID]:org id' \
    '--version[Show version]' \
    '(--help -h)'{--help,-h}'[Show help]' \
    '*:: :->command'
}

_stemplin_id_arg() {
  _arguments -S \
    ':id'
}

_stemplin_me() { : }

_stemplin_orgs() {
  local -a actions
  actions=(
    'list:List your organizations'
    'show:Show organization details'
  )
  _arguments -S \
    '1:action:->action' \
    '*:: :->args'

  case "$state" in
    action) _describe 'action' actions ;;
    args)
      case "${words[1]}" in
        show) _stemplin_id_arg ;;
      esac
      ;;
  esac
}

_stemplin_clients() {
  local -a actions
  actions=(
    'list:List clients'
    'show:Show client details'
    'create:Create a client'
    'update:Update a client'
    'delete:Delete a client'
  )
  _arguments -S \
    '1:action:->action' \
    '*:: :->args'

  case "$state" in
    action) _describe 'action' actions ;;
    args)
      case "${words[1]}" in
        show|delete) _stemplin_id_arg ;;
        create) _arguments -S '--name[Client name]:name' ;;
        update) _arguments -S ':id' '--name[Client name]:name' ;;
      esac
      ;;
  esac
}

_stemplin_projects() {
  local -a actions
  actions=(
    'list:List projects'
    'show:Show project details'
    'create:Create a project'
    'update:Update a project'
    'delete:Delete a project'
  )
  _arguments -S \
    '1:action:->action' \
    '*:: :->args'

  case "$state" in
    action) _describe 'action' actions ;;
    args)
      case "${words[1]}" in
        show|delete) _stemplin_id_arg ;;
        create)
          _arguments -S \
            '--name[Project name]:name' \
            '--client[Client ID]:client id' \
            '--rate[Rate amount]:rate' \
            '--billable[Billable]:billable:(true false)' \
            '--desc[Description]:description' \
            '--tasks[Assigned tasks JSON]:json'
          ;;
        update)
          _arguments -S \
            ':id' \
            '--name[Project name]:name' \
            '--client[Client ID]:client id' \
            '--rate[Rate amount]:rate' \
            '--billable[Billable]:billable:(true false)' \
            '--desc[Description]:description' \
            '--tasks[Assigned tasks JSON]:json'
          ;;
      esac
      ;;
  esac
}

_stemplin_tasks() {
  local -a actions
  actions=(
    'list:List tasks'
    'show:Show task details'
  )
  _arguments -S \
    '1:action:->action' \
    '*:: :->args'

  case "$state" in
    action) _describe 'action' actions ;;
    args)
      case "${words[1]}" in
        show) _stemplin_id_arg ;;
      esac
      ;;
  esac
}

_stemplin_time() {
  local -a actions
  actions=(
    'list:List time entries'
    'show:Show a time entry'
    'create:Create a time entry'
    'update:Update a time entry'
    'delete:Delete a time entry'
    'timer:Toggle timer on a time entry'
  )
  _arguments -S \
    '1:action:->action' \
    '*:: :->args'

  case "$state" in
    action) _describe 'action' actions ;;
    args)
      case "${words[1]}" in
        show|delete|timer) _stemplin_id_arg ;;
        list)
          _arguments -S \
            '--date[Single date (YYYY-MM-DD)]:date' \
            '--from[Start date (YYYY-MM-DD)]:date' \
            '--to[End date (YYYY-MM-DD)]:date' \
            '--project[Filter by project ID]:project id' \
            '--per-page[Results per page]:number'
          ;;
        create)
          _arguments -S \
            '--task[Assigned task ID]:task id' \
            '--minutes[Minutes worked]:minutes' \
            '--date[Date (YYYY-MM-DD)]:date' \
            '--notes[Notes]:notes'
          ;;
        update)
          _arguments -S \
            ':id' \
            '--task[Assigned task ID]:task id' \
            '--minutes[Minutes worked]:minutes' \
            '--date[Date (YYYY-MM-DD)]:date' \
            '--notes[Notes]:notes'
          ;;
      esac
      ;;
  esac
}

_stemplin_users() {
  local -a actions
  actions=(
    'list:List users'
    'show:Show user details'
    'me:Show your profile'
  )
  _arguments -S \
    '1:action:->action' \
    '*:: :->args'

  case "$state" in
    action) _describe 'action' actions ;;
    args)
      case "${words[1]}" in
        show) _stemplin_id_arg ;;
      esac
      ;;
  esac
}

_stemplin_reports() {
  local -a actions
  actions=(
    'show:Show time report'
  )
  _arguments -S \
    '1:action:->action' \
    '*:: :->args'

  case "$state" in
    action) _describe 'action' actions ;;
    args)
      case "${words[1]}" in
        show)
          _arguments -S \
            '--from[Start date (YYYY-MM-DD)]:date' \
            '--to[End date (YYYY-MM-DD)]:date' \
            '--clients[Client IDs (comma-separated)]:client ids' \
            '--projects[Project IDs (comma-separated)]:project ids' \
            '--users[User IDs (comma-separated)]:user ids' \
            '--tasks[Task IDs (comma-separated)]:task ids'
          ;;
      esac
      ;;
  esac
}

_stemplin_token() {
  local -a actions
  actions=(
    'regenerate:Generate a new API token'
  )
  _arguments -S \
    '1:action:->action'

  case "$state" in
    action) _describe 'action' actions ;;
  esac
}

_stemplin_help() {
  _arguments -S \
    '1:command:->cmd'

  case "$state" in
    cmd) _describe 'command' commands ;;
  esac
}

_stemplin() {
  _stemplin_global_flags

  case "$state" in
    command)
      if (( CURRENT == 1 )); then
        _describe 'command' commands
      else
        local cmd="${words[1]}"
        case "$cmd" in
          me)       _stemplin_me ;;
          orgs)     _stemplin_orgs ;;
          clients)  _stemplin_clients ;;
          projects) _stemplin_projects ;;
          tasks)    _stemplin_tasks ;;
          time)     _stemplin_time ;;
          users)    _stemplin_users ;;
          reports)  _stemplin_reports ;;
          token)    _stemplin_token ;;
          help)     _stemplin_help ;;
        esac
      fi
      ;;
  esac
}

_stemplin "$@"
