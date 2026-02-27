#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- token regenerate ---
_test "token regenerate shows new token"
reset_mock
MOCK_API_RESPONSE='{"api_token":"new-secret-token-abc123"}'
output=$(cmd_token regenerate)
_load_mock_state
assert_equals "PATCH" "$LAST_API_METHOD"
assert_equals "/api_token" "$LAST_API_PATH"
assert_contains "New token: new-secret-token-abc123" "$output"
assert_contains "Update STEMPLIN_API_TOKEN" "$output"

# --- token regenerate raw ---
_test "token regenerate --raw"
reset_mock
RAW=true
MOCK_API_RESPONSE='{"api_token":"new-secret-token-abc123"}'
output=$(cmd_token regenerate)
assert_contains '"api_token":"new-secret-token-abc123"' "$output"

# --- token no action ---
_test "token without action shows usage"
reset_mock
output=$(cmd_token 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Usage:" "$output"

# --- token unknown action ---
_test "token unknown action shows usage"
reset_mock
output=$(cmd_token bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Usage:" "$output"

_print_summary
