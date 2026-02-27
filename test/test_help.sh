#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- General help ---
_test "help shows version and commands"
output=$(cmd_help)
assert_contains "stemplin v0.1.0" "$output"
assert_contains "Commands:" "$output"
assert_contains "me" "$output"
assert_contains "clients" "$output"
assert_contains "time" "$output"
assert_contains "reports" "$output"
assert_contains "--raw" "$output"

# --- Topic help ---
_test "help me"
output=$(cmd_help me)
assert_contains "stemplin me" "$output"

_test "help orgs"
output=$(cmd_help orgs)
assert_contains "orgs list" "$output"
assert_contains "orgs show" "$output"

_test "help clients"
output=$(cmd_help clients)
assert_contains "clients create" "$output"
assert_contains "--name NAME" "$output"
assert_contains "clients delete" "$output"

_test "help projects"
output=$(cmd_help projects)
assert_contains "projects create" "$output"
assert_contains "--billable" "$output"
assert_contains "--tasks JSON" "$output"

_test "help tasks"
output=$(cmd_help tasks)
assert_contains "tasks list" "$output"

_test "help time"
output=$(cmd_help time)
assert_contains "time create" "$output"
assert_contains "--task ID" "$output"
assert_contains "time timer" "$output"

_test "help users"
output=$(cmd_help users)
assert_contains "users list" "$output"
assert_contains "users me" "$output"

_test "help reports"
output=$(cmd_help reports)
assert_contains "reports show" "$output"
assert_contains "--from" "$output"
assert_contains "--clients" "$output"

_test "help token"
output=$(cmd_help token)
assert_contains "token regenerate" "$output"

# --- Unknown help topic ---
_test "help unknown topic exits with error"
output=$(cmd_help "nonexistent" 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "No help for: nonexistent" "$output"

# --- _minutes_to_hm ---
_test "_minutes_to_hm formats correctly"
assert_equals "2:30" "$(_minutes_to_hm 150)"
assert_equals "0:00" "$(_minutes_to_hm 0)"
assert_equals "1:05" "$(_minutes_to_hm 65)"
assert_equals "10:00" "$(_minutes_to_hm 600)"

# --- _today override ---
_test "_today returns mocked date"
assert_equals "2026-02-27" "$(_today)"

_print_summary
