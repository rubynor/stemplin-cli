#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- projects list ---
_test "projects list shows table"
reset_mock
MOCK_API_RESPONSE='[{"id":1,"name":"Website","client_name":"Acme","billable":true,"rate_currency":"150.00"},{"id":2,"name":"App","client_name":null,"billable":false,"rate_currency":null}]'
output=$(cmd_projects list)
_load_mock_state
assert_contains "ID" "$output"
assert_contains "NAME" "$output"
assert_contains "BILLABLE" "$output"
assert_contains "Website" "$output"
assert_contains "Acme" "$output"
assert_contains "yes" "$output"
assert_contains "App" "$output"
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/projects" "$LAST_API_PATH"

# --- projects show ---
_test "projects show"
reset_mock
MOCK_API_RESPONSE='{"id":1,"name":"Website","billable":true}'
output=$(cmd_projects show 1)
_load_mock_state
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/projects/1" "$LAST_API_PATH"
assert_contains "Website" "$output"

# --- projects show missing id ---
_test "projects show requires ID"
reset_mock
output=$(cmd_projects show 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- projects create minimal ---
_test "projects create with name only"
reset_mock
MOCK_API_RESPONSE='{"id":3,"name":"New Proj"}'
cmd_projects create --name "New Proj" >/dev/null
_load_mock_state
assert_equals "POST" "$LAST_API_METHOD"
assert_equals "/projects" "$LAST_API_PATH"
assert_contains '"name": "New Proj"' "$LAST_API_BODY"

# --- projects create with all flags ---
_test "projects create with all flags"
reset_mock
MOCK_API_RESPONSE='{"id":4,"name":"Full","billable":true}'
cmd_projects create --name "Full" --client 5 --rate "200.00" --billable true --desc "A project" --tasks '[{"task_id":1}]' >/dev/null
_load_mock_state
assert_equals "POST" "$LAST_API_METHOD"
assert_contains '"name": "Full"' "$LAST_API_BODY"
assert_contains '"client_id": 5' "$LAST_API_BODY"
assert_contains '"rate_currency": "200.00"' "$LAST_API_BODY"
assert_contains '"billable": true' "$LAST_API_BODY"
assert_contains '"description": "A project"' "$LAST_API_BODY"
assert_contains '"assigned_tasks_attributes"' "$LAST_API_BODY"

# --- projects create missing name ---
_test "projects create requires --name"
reset_mock
output=$(cmd_projects create 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- projects update ---
_test "projects update sends PATCH"
reset_mock
MOCK_API_RESPONSE='{"id":1,"name":"Updated Proj"}'
cmd_projects update 1 --name "Updated Proj" --billable false >/dev/null
_load_mock_state
assert_equals "PATCH" "$LAST_API_METHOD"
assert_equals "/projects/1" "$LAST_API_PATH"
assert_contains '"name": "Updated Proj"' "$LAST_API_BODY"
assert_contains '"billable": false' "$LAST_API_BODY"

# --- projects update missing id ---
_test "projects update requires ID"
reset_mock
output=$(cmd_projects update 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- projects delete ---
_test "projects delete"
reset_mock
MOCK_API_STATUS="204"
output=$(cmd_projects delete 1)
_load_mock_state
assert_equals "DELETE" "$LAST_API_METHOD"
assert_equals "/projects/1" "$LAST_API_PATH"
assert_contains "Deleted." "$output"

# --- unknown action ---
_test "projects unknown action"
reset_mock
output=$(cmd_projects bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown projects action" "$output"

_print_summary
