#!/usr/bin/env bash
set -euo pipefail

# Save real env vars BEFORE helpers.sh overwrites them with mock values
_REAL_URL="${STEMPLIN_URL:-}"
_REAL_TOKEN="${STEMPLIN_API_TOKEN:-}"
_REAL_ORG="${STEMPLIN_ORG_ID:-}"

source "$(dirname "$0")/helpers.sh"

# --- Skip if real env vars were not set ---
if [[ -z "$_REAL_URL" ]] || [[ -z "$_REAL_TOKEN" ]] || [[ -z "$_REAL_ORG" ]]; then
  echo "  test_integration: SKIPPED (set STEMPLIN_URL, STEMPLIN_API_TOKEN, STEMPLIN_ORG_ID to run)"
  echo "0:0"
  exit 0
fi

# Restore real _api function and env vars (env vars AFTER source, since
# sourcing the CLI re-reads ~/.stemplinrc which would overwrite them)
__TESTING__=1 source "$CLI_PATH"
export STEMPLIN_URL="$_REAL_URL"
export STEMPLIN_API_TOKEN="$_REAL_TOKEN"
export STEMPLIN_ORG_ID="$_REAL_ORG"
unset -f _today

# ---------------------------------------------------------------------------
# Integration tests against a live server
# ---------------------------------------------------------------------------

_test "integration: me"
output=$(cmd_me)
assert_contains "ID" "$output" "me returns ID"
assert_contains "Name" "$output" "me returns Name"
assert_contains "Email" "$output" "me returns Email"

_test "integration: orgs list"
output=$(cmd_orgs list)
assert_contains "ID" "$output" "orgs list has ID header"

_test "integration: tasks list"
output=$(cmd_tasks list)
assert_contains "ID" "$output" "tasks list has ID header"

_test "integration: users list"
output=$(cmd_users list)
assert_contains "ID" "$output" "users list has ID header"

# --- Client CRUD ---
_test "integration: client CRUD"
create_out=$(cmd_clients create --name "CLI Test Client $(date +%s)")
client_id=$(echo "$create_out" | jq -r '.id')
assert_matches '^[0-9]+$' "$client_id" "client created with numeric ID"

show_out=$(cmd_clients show "$client_id")
assert_contains "CLI Test Client" "$show_out" "client show returns name"

update_out=$(cmd_clients update "$client_id" --name "Updated CLI Client")
assert_contains "Updated CLI Client" "$update_out" "client updated"

list_out=$(cmd_clients list)
assert_contains "Updated CLI Client" "$list_out" "client appears in list"

delete_out=$(cmd_clients delete "$client_id")
assert_contains "Deleted." "$delete_out" "client deleted"

# --- Project CRUD ---
_test "integration: project CRUD"
client_out=$(cmd_clients create --name "Proj Test Client $(date +%s)")
client_id=$(echo "$client_out" | jq -r '.id')

# Get a task ID from the org to use for project creation
task_list_out=$(_api GET /tasks)
first_task_id=$(echo "$task_list_out" | jq -r '.[0].id')

create_out=$(cmd_projects create --name "CLI Test Proj $(date +%s)" --client "$client_id" --tasks "[{\"task_id\": $first_task_id}]")
project_id=$(echo "$create_out" | jq -r '.id')
assert_matches '^[0-9]+$' "$project_id" "project created"

show_out=$(cmd_projects show "$project_id")
assert_contains "CLI Test Proj" "$show_out" "project show"

update_out=$(cmd_projects update "$project_id" --name "Updated Proj")
assert_contains "Updated Proj" "$update_out" "project updated"

cmd_projects delete "$project_id" >/dev/null
cmd_clients delete "$client_id" >/dev/null

# --- Reports ---
_test "integration: reports show"
output=$(cmd_reports show --from 2020-01-01 --to 2030-12-31)
assert_contains "Total:" "$output" "reports show has total"

_test "integration: reports detailed"
output=$(cmd_reports detailed --from 2020-01-01 --to 2030-12-31)
assert_contains "Total:" "$output" "reports detailed has total"
assert_contains "Billable:" "$output" "reports detailed has billable"

_print_summary
