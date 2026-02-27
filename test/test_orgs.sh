#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- orgs list ---
_test "orgs list shows table"
reset_mock
MOCK_API_RESPONSE='[{"id":1,"name":"Rubynor","currency":"NOK"},{"id":2,"name":"Other","currency":null}]'
output=$(cmd_orgs list)
_load_mock_state
assert_contains "ID" "$output"
assert_contains "NAME" "$output"
assert_contains "CURRENCY" "$output"
assert_contains "Rubynor" "$output"
assert_contains "NOK" "$output"
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/organizations" "$LAST_API_PATH"

# --- orgs show ---
_test "orgs show"
reset_mock
MOCK_API_RESPONSE='{"id":1,"name":"Rubynor","currency":"NOK"}'
output=$(cmd_orgs show 1)
_load_mock_state
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/organizations/1" "$LAST_API_PATH"
assert_contains "Rubynor" "$output"

# --- orgs show missing id ---
_test "orgs show requires ID"
reset_mock
output=$(cmd_orgs show 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- unknown action ---
_test "orgs unknown action"
reset_mock
output=$(cmd_orgs bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown orgs action" "$output"

_print_summary
