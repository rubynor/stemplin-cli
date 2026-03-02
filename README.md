# stemplin-cli

Command-line interface and Claude Code skill for the [Stemplin](https://stemplin.com) time tracking API.

## Install

**From a clone:**

```bash
git clone https://github.com/rubynor/stemplin-cli.git
cd stemplin-cli
bash install.sh
```

**One-liner (downloads from GitHub):**

```bash
curl -sSL https://raw.githubusercontent.com/rubynor/stemplin-cli/master/install.sh | bash
```

The installer places:
- `bin/stemplin` → `~/bin/stemplin`
- `skill/stemplin-api.md` → `~/.claude/skills/stemplin-api.md`
- `completions/stemplin.bash` → `~/.local/share/bash-completion/completions/stemplin`

Make sure `~/bin` is in your `PATH`:

```bash
export PATH="$HOME/bin:$PATH"
```

## Configuration

Set these environment variables (or put them in `~/.stemplinrc`):

```bash
export STEMPLIN_URL="https://app.stemplin.com" # or http://localhost:3000
export STEMPLIN_API_TOKEN="your-token-here"
export STEMPLIN_ORG_ID=""                       # optional
```

Get your API token from the Stemplin web UI (Profile → API Token) or with `stemplin me` after initial setup.

## Usage

```
stemplin [--raw] [--org ID] <command> [action] [flags]
```

### Commands

| Command | Actions | Description |
|---------|---------|-------------|
| `me` | — | Show your profile and token |
| `orgs` | `list`, `show ID` | Organizations |
| `clients` | `list`, `show`, `create`, `update`, `delete` | Clients |
| `projects` | `list`, `show`, `create`, `update`, `delete` | Projects |
| `tasks` | `list`, `show` | Tasks |
| `time` | `list`, `show`, `create`, `update`, `delete`, `timer` | Time entries |
| `users` | `list`, `show`, `me` | Users |
| `reports` | `show` | Time reports |
| `token` | `regenerate` | API token management |
| `help` | `[command]` | Show help |

### Examples

```bash
# See your profile
stemplin me

# List today's time entries (default)
stemplin time list

# Log 2 hours on assigned task 42
stemplin time create --task 42 --minutes 120 --notes "Feature work"

# Start a timer
stemplin time create --task 42 --minutes 0
stemplin time timer 123    # toggle on

# Weekly report
stemplin reports show --from 2025-01-13 --to 2025-01-19

# List projects
stemplin projects list

# Create a client
stemplin clients create --name "Acme Corp"

# Raw JSON output
stemplin --raw time list
```

### Time Entry Flags

```bash
stemplin time list [--date YYYY-MM-DD] [--from DATE --to DATE] [--project ID] [--per-page N]
stemplin time create --task ID [--minutes N] [--date YYYY-MM-DD] [--notes TEXT]
stemplin time update ID [--task ID] [--minutes N] [--date YYYY-MM-DD] [--notes TEXT]
```

### Report Flags

```bash
stemplin reports show [--from DATE] [--to DATE] [--clients IDS] [--projects IDS] [--users IDS] [--tasks IDS]
```

IDs are comma-separated (e.g. `--projects 1,2,3`).

## Claude Code Skill

The installer places `stemplin-api.md` in `~/.claude/skills/`. This enables Claude Code to use the Stemplin API from any terminal conversation:

> "Log 2 hours on the website project for today"
> "What did I work on this week?"
> "Show me a report for January"

Claude will use the `stemplin` CLI or raw `curl` commands to interact with the API.

## Dependencies

- `curl`
- `jq`
- `column` (usually pre-installed)

## Tab Completion

The installer sets up bash completion automatically. To load manually:

```bash
source completions/stemplin.bash
```

## License

MIT
