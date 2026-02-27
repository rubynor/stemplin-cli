#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- users list ---
_test "users list shows table"
reset_mock
MOCK_API_RESPONSE='[{"id":1,"name":"Alice","email":"alice@example.com"},{"id":2,"name":"Bob","email":"bob@example.com"}]'
output=$(cmd_users list)
_load_mock_state
assert_contains "ID" "$output"
assert_contains "NAME" "$output"
assert_contains "EMAIL" "$output"
assert_contains "Alice" "$output"
assert_contains "bob@example.com" "$output"
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/users" "$LAST_API_PATH"

# --- users show ---
_test "users show"
reset_mock
MOCK_API_RESPONSE='{"id":1,"name":"Alice","email":"alice@example.com"}'
output=$(cmd_users show 1)
_load_mock_state
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/users/1" "$LAST_API_PATH"
assert_contains "Alice" "$output"

# --- users show missing id ---
_test "users show requires ID"
reset_mock
output=$(cmd_users show 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- users me delegates to cmd_me ---
_test "users me calls cmd_me"
reset_mock
MOCK_API_RESPONSE='{"id":42,"name":"Mario","email":"mario@example.com","locale":"en","has_api_token":true,"current_organization":{"id":1,"name":"Rubynor"}}'
output=$(cmd_users me)
_load_mock_state
assert_contains "Mario" "$output"
assert_equals "/users/me" "$LAST_API_PATH"

# --- unknown action ---
_test "users unknown action"
reset_mock
output=$(cmd_users bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown users action" "$output"

_print_summary
