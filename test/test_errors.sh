#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- 401 Unauthorized ---
_test "401 error message"
reset_mock
MOCK_API_STATUS="401"
output=$(cmd_clients list 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unauthorized (401)" "$output"

# --- 403 Forbidden ---
_test "403 error message"
reset_mock
MOCK_API_STATUS="403"
output=$(cmd_clients show 1 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Forbidden (403)" "$output"

# --- 404 Not Found ---
_test "404 error message"
reset_mock
MOCK_API_STATUS="404"
output=$(cmd_clients show 999 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Not found (404)" "$output"

# --- 422 Validation error ---
_test "422 error message"
reset_mock
MOCK_API_STATUS="422"
MOCK_API_RESPONSE="Name can't be blank"
output=$(cmd_clients create --name "x" 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Validation error (422)" "$output"

# --- need_var checks ---
_test "missing STEMPLIN_URL"
reset_mock
local_url="$STEMPLIN_URL"
unset STEMPLIN_URL
output=$(need_var STEMPLIN_URL 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "STEMPLIN_URL is not set" "$output"
export STEMPLIN_URL="$local_url"

_test "missing STEMPLIN_API_TOKEN"
reset_mock
local_token="$STEMPLIN_API_TOKEN"
unset STEMPLIN_API_TOKEN
output=$(need_var STEMPLIN_API_TOKEN 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "STEMPLIN_API_TOKEN is not set" "$output"
export STEMPLIN_API_TOKEN="$local_token"

# --- die function ---
_test "die prints to stderr and exits 1"
output=$(die "something went wrong" 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Error: something went wrong" "$output"

_print_summary
