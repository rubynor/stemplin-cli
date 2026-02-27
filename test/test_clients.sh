#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- clients list ---
_test "clients list shows table"
reset_mock
MOCK_API_RESPONSE='[{"id":1,"name":"Acme Corp"},{"id":2,"name":"Beta Inc"}]'
output=$(cmd_clients list)
_load_mock_state
assert_contains "ID" "$output"
assert_contains "NAME" "$output"
assert_contains "Acme Corp" "$output"
assert_contains "Beta Inc" "$output"
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/clients" "$LAST_API_PATH"

# --- clients list raw ---
_test "clients list --raw"
reset_mock
RAW=true
MOCK_API_RESPONSE='[{"id":1,"name":"Acme Corp"}]'
output=$(cmd_clients list)
assert_contains '"id":1' "$output"

# --- clients show ---
_test "clients show"
reset_mock
MOCK_API_RESPONSE='{"id":1,"name":"Acme Corp","created_at":"2026-01-01"}'
output=$(cmd_clients show 1)
_load_mock_state
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/clients/1" "$LAST_API_PATH"
assert_contains "Acme Corp" "$output"

# --- clients show missing id ---
_test "clients show requires ID"
reset_mock
output=$(cmd_clients show 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Usage:" "$output"

# --- clients create ---
_test "clients create sends POST with name"
reset_mock
MOCK_API_RESPONSE='{"id":3,"name":"New Client"}'
output=$(cmd_clients create --name "New Client")
_load_mock_state
assert_equals "POST" "$LAST_API_METHOD"
assert_equals "/clients" "$LAST_API_PATH"
assert_contains '"name": "New Client"' "$LAST_API_BODY"
assert_contains "New Client" "$output"

# --- clients create missing name ---
_test "clients create requires --name"
reset_mock
output=$(cmd_clients create 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Usage:" "$output"

# --- clients create unknown flag ---
_test "clients create unknown flag"
reset_mock
output=$(cmd_clients create --bogus foo 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown flag" "$output"

# --- clients update ---
_test "clients update sends PATCH"
reset_mock
MOCK_API_RESPONSE='{"id":1,"name":"Updated"}'
output=$(cmd_clients update 1 --name "Updated")
_load_mock_state
assert_equals "PATCH" "$LAST_API_METHOD"
assert_equals "/clients/1" "$LAST_API_PATH"
assert_contains '"name": "Updated"' "$LAST_API_BODY"

# --- clients update missing id ---
_test "clients update requires ID"
reset_mock
output=$(cmd_clients update 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- clients delete ---
_test "clients delete sends DELETE"
reset_mock
MOCK_API_STATUS="204"
output=$(cmd_clients delete 1)
_load_mock_state
assert_equals "DELETE" "$LAST_API_METHOD"
assert_equals "/clients/1" "$LAST_API_PATH"
assert_contains "Deleted." "$output"

# --- clients delete missing id ---
_test "clients delete requires ID"
reset_mock
output=$(cmd_clients delete 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- unknown action ---
_test "clients unknown action"
reset_mock
output=$(cmd_clients bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown clients action" "$output"

_print_summary
