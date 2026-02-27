#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- reports show formatted ---
_test "reports show formatted output"
reset_mock
MOCK_API_RESPONSE='{
  "total_minutes": 480,
  "total_entries": 5,
  "by_project": [
    {"project_name":"Website","client_name":"Acme","total_minutes":300,"total_entries":3},
    {"project_name":"App","client_name":"Beta","total_minutes":180,"total_entries":2}
  ],
  "by_user": [
    {"user_name":"Alice","total_minutes":300,"total_entries":3},
    {"user_name":"Bob","total_minutes":180,"total_entries":2}
  ]
}'
output=$(cmd_reports show)
_load_mock_state
assert_contains "Total: 8:00 (5 entries)" "$output"
assert_contains "By Project:" "$output"
assert_contains "Website" "$output"
assert_contains "Acme" "$output"
assert_contains "By User:" "$output"
assert_contains "Alice" "$output"
assert_contains "Bob" "$output"
assert_equals "GET" "$LAST_API_METHOD"

# --- reports show with filters ---
_test "reports show --from --to builds query string"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":0,"total_entries":0,"by_project":[],"by_user":[]}'
cmd_reports show --from 2026-01-01 --to 2026-01-31 >/dev/null
_load_mock_state
assert_contains "start_date=2026-01-01" "$LAST_API_PATH"
assert_contains "end_date=2026-01-31" "$LAST_API_PATH"

# --- reports show --clients --projects --users --tasks ---
_test "reports show all filter flags"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":0,"total_entries":0,"by_project":[],"by_user":[]}'
cmd_reports show --clients 1,2 --projects 3 --users 4,5 --tasks 6 >/dev/null
_load_mock_state
assert_contains "client_ids=1,2" "$LAST_API_PATH"
assert_contains "project_ids=3" "$LAST_API_PATH"
assert_contains "user_ids=4,5" "$LAST_API_PATH"
assert_contains "task_ids=6" "$LAST_API_PATH"

# --- reports show raw ---
_test "reports show --raw"
reset_mock
RAW=true
MOCK_API_RESPONSE='{"total_minutes":480,"total_entries":5,"by_project":[],"by_user":[]}'
output=$(cmd_reports show)
assert_contains '"total_minutes":480' "$output"

# --- reports unknown action ---
_test "reports unknown action"
reset_mock
output=$(cmd_reports bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown reports action" "$output"

_print_summary
