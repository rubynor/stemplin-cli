#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- me command formatted ---
_test "me shows formatted profile"
reset_mock
MOCK_API_RESPONSE='{"id":42,"name":"Mario","email":"mario@example.com","locale":"en","has_api_token":true,"current_organization":{"id":1,"name":"Rubynor"}}'
output=$(cmd_me)
_load_mock_state
assert_contains "42" "$output"
assert_contains "Mario" "$output"
assert_contains "mario@example.com" "$output"
assert_contains "en" "$output"
assert_contains "Rubynor" "$output"
assert_contains "yes" "$output"
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/users/me" "$LAST_API_PATH"

# --- me with has_api_token false ---
_test "me shows 'no' when no token"
reset_mock
MOCK_API_RESPONSE='{"id":42,"name":"Mario","email":"mario@example.com","locale":"en","has_api_token":false,"current_organization":{"id":1,"name":"Rubynor"}}'
output=$(cmd_me)
assert_contains "no" "$output"

# --- me raw mode ---
_test "me --raw outputs raw JSON"
reset_mock
RAW=true
MOCK_API_RESPONSE='{"id":42,"name":"Mario","email":"mario@example.com","locale":"en","has_api_token":true,"current_organization":{"id":1,"name":"Rubynor"}}'
output=$(cmd_me)
assert_contains '"id":42' "$output"
assert_contains '"name":"Mario"' "$output"

# --- me with no org ---
_test "me with null org"
reset_mock
MOCK_API_RESPONSE='{"id":42,"name":"Mario","email":"mario@example.com","locale":"en","has_api_token":true,"current_organization":{"id":null,"name":null}}'
output=$(cmd_me)
assert_contains "Mario" "$output"

_print_summary
