---
name: stemplin-api
description: Stemplin time tracking API — CRUD for time entries, projects, clients, reports. Use when user asks about time tracking, logging time, timers, weekly reports, projects, or clients in Stemplin.
triggers:
  - stemplin
  - time tracking
  - log time
  - timer
  - time entry
  - time entries
  - weekly report
  - projects list
  - clients list
---

# Stemplin API Skill

Interact with the Stemplin time tracking REST API. All requests use `curl` with JSON.

## Auth & Config

```bash
# Required env vars (or set in ~/.stemplinrc)
STEMPLIN_URL      # e.g. https://stemplin.com or http://localhost:3000
STEMPLIN_API_TOKEN # Bearer token from /users/me or web UI
STEMPLIN_ORG_ID    # Optional, sets X-Organization-Id header
```

**Base curl pattern:**
```bash
curl -s \
  -H "Authorization: Bearer $STEMPLIN_API_TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-Organization-Id: $STEMPLIN_ORG_ID" \
  "$STEMPLIN_URL/api/v1/ENDPOINT"
```

If the `stemplin` CLI is installed (`~/bin/stemplin`), prefer using it directly (e.g. `stemplin time list`, `stemplin me`). Fall back to raw curl if the CLI is not available.

## Endpoints

| Method | Path | Body / Params | Notes |
|--------|------|---------------|-------|
| GET | /users/me | — | Current user + api_token + current_organization |
| GET | /organizations | — | List user's orgs |
| GET | /organizations/:id | — | Org details |
| GET | /clients | — | List clients |
| GET | /clients/:id | — | Client details |
| POST | /clients | `{client: {name}}` | Create client |
| PATCH | /clients/:id | `{client: {name}}` | Update client |
| DELETE | /clients/:id | — | Soft-delete |
| GET | /projects | — | List projects |
| GET | /projects/:id | — | Project + assigned_tasks array |
| POST | /projects | `{project: {name, client_id, rate_currency, billable, description, assigned_tasks_attributes}}` | Create project |
| PATCH | /projects/:id | same as create | Update project |
| DELETE | /projects/:id | — | Soft-delete |
| GET | /tasks | — | List org tasks |
| GET | /tasks/:id | — | Task details |
| GET | /time_regs | `?date=&start_date=&end_date=&project_id=&per_page=` | List time entries (paginated) |
| GET | /time_regs/:id | — | Time entry details |
| POST | /time_regs | `{time_reg: {assigned_task_id, minutes, date_worked, notes}}` | Create time entry |
| PATCH | /time_regs/:id | same fields | Update time entry |
| DELETE | /time_regs/:id | — | Soft-delete |
| PATCH | /time_regs/:id/timer | — | Toggle timer (start/stop) |
| GET | /reports | `?start_date=&end_date=&client_ids=&project_ids=&user_ids=&task_ids=` | Report with totals |
| PATCH | /api_token | — | Regenerate API token |
| GET | /users | — | List org users |
| GET | /users/:id | — | User details |

## Response Shapes

**User (/users/me):**
```json
{"id": 1, "email": "...", "first_name": "...", "last_name": "...", "name": "...", "locale": "en",
 "has_api_token": true, "current_organization": {"id": 1, "name": "..."}}
```

**Organization:**
```json
{"id": 1, "name": "...", "currency": "NOK"}
```

**Client:**
```json
{"id": 1, "name": "...", "organization_id": 1}
```

**Project:**
```json
{"id": 1, "name": "...", "description": "...", "billable": true, "rate": 15000, "rate_currency": "150.00",
 "client_id": 1, "client_name": "...",
 "assigned_tasks": [{"id": 1, "task_id": 1, "task_name": "Development", "rate": 15000, "rate_currency": "150.00"}]}
```

**Task:**
```json
{"id": 1, "name": "Development", "organization_id": 1}
```

**Time Entry:**
```json
{"id": 1, "notes": "...", "minutes": 60, "date_worked": "2025-01-15",
 "assigned_task_id": 1, "user_id": 1, "start_time": null,
 "current_minutes": 60, "active": false,
 "task_name": "Development", "project_id": 1, "project_name": "...", "client_name": "..."}
```

**Time Entries List (paginated):**
```json
{"time_regs": [...], "pagination": {"current_page": 1, "total_pages": 1, "total_count": 5}}
```

**Report:**
```json
{"total_minutes": 480, "total_entries": 3,
 "by_project": [{"project_id": 1, "project_name": "...", "client_name": "...", "total_minutes": 300, "total_entries": 2}],
 "by_user": [{"user_id": 1, "user_name": "...", "total_minutes": 480, "total_entries": 3}]}
```

## Error Responses

All errors return: `{"errors": ["message"]}`

| Code | Meaning | Recovery |
|------|---------|----------|
| 401 | Bad/missing token | Check STEMPLIN_API_TOKEN |
| 403 | No permission | Check org membership/role |
| 404 | Resource not found | Verify ID exists |
| 422 | Validation failed | Check required fields |

## Workflows

### Log time for a project

1. Find the project: `GET /projects` (or `stemplin projects list`)
2. Get assigned tasks: `GET /projects/:id` — look at `assigned_tasks[].id`
3. Create time entry: `POST /time_regs` with `assigned_task_id`, `minutes`, `date_worked`

```bash
# Example: log 2 hours on task 42 for today
stemplin time create --task 42 --minutes 120 --notes "Feature work"
```

### Start/stop a timer

1. Create a time entry with 0 minutes: `stemplin time create --task 42 --minutes 0`
2. Start the timer: `stemplin time timer <ID>` (toggles active state)
3. Stop the timer: `stemplin time timer <ID>` again (accumulates minutes)

### Weekly report

```bash
# This week
stemplin reports show --from 2025-01-13 --to 2025-01-19

# Filter by project
stemplin reports show --from 2025-01-13 --to 2025-01-19 --projects 1,2
```

### What did I do today?

```bash
stemplin time list
# Defaults to --date today
```

### What did I do this week?

```bash
stemplin time list --from $(date -d 'last monday' +%Y-%m-%d) --to $(date +%Y-%m-%d) --per-page 100
```

## Tips

- `assigned_task_id` is NOT the same as `task_id`. Use `GET /projects/:id` to find the assigned task IDs for a project.
- Rate is stored in hundredths (15000 = 150.00). Use `rate_currency` for the human-readable format.
- `time list` defaults to today. Use `--from`/`--to` for date ranges.
- Timer toggle: `PATCH /time_regs/:id/timer`. When active, `current_minutes` auto-increments.
- All deletes are soft-deletes (records can be restored).
