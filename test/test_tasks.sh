#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- tasks list ---
_test "tasks list shows table"
reset_mock
MOCK_API_RESPONSE='[{"id":1,"name":"Development"},{"id":2,"name":"Design"}]'
output=$(cmd_tasks list)
_load_mock_state
assert_contains "ID" "$output"
assert_contains "NAME" "$output"
assert_contains "Development" "$output"
assert_contains "Design" "$output"
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/tasks" "$LAST_API_PATH"

# --- tasks show ---
_test "tasks show"
reset_mock
MOCK_API_RESPONSE='{"id":1,"name":"Development"}'
output=$(cmd_tasks show 1)
_load_mock_state
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/tasks/1" "$LAST_API_PATH"
assert_contains "Development" "$output"

# --- tasks show missing id ---
_test "tasks show requires ID"
reset_mock
output=$(cmd_tasks show 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- unknown action ---
_test "tasks unknown action"
reset_mock
output=$(cmd_tasks bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown tasks action" "$output"

_print_summary
