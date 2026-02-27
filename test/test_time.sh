#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- time list defaults to today ---
_test "time list defaults to today's date"
reset_mock
MOCK_API_RESPONSE='{"time_regs":[]}'
cmd_time list >/dev/null 2>&1 || true
_load_mock_state
assert_equals "GET" "$LAST_API_METHOD"
assert_contains "date=2026-02-27" "$LAST_API_PATH"

# --- time list with --date ---
_test "time list --date"
reset_mock
MOCK_API_RESPONSE='{"time_regs":[]}'
cmd_time list --date 2026-01-15 >/dev/null 2>&1 || true
_load_mock_state
assert_contains "date=2026-01-15" "$LAST_API_PATH"
assert_not_contains "start_date" "$LAST_API_PATH"

# --- time list with --from/--to ---
_test "time list --from --to"
reset_mock
MOCK_API_RESPONSE='{"time_regs":[]}'
cmd_time list --from 2026-01-01 --to 2026-01-31 >/dev/null 2>&1 || true
_load_mock_state
assert_contains "start_date=2026-01-01" "$LAST_API_PATH"
assert_contains "end_date=2026-01-31" "$LAST_API_PATH"
assert_not_contains "date=2026-02-27" "$LAST_API_PATH"

# --- time list with --project ---
_test "time list --project"
reset_mock
MOCK_API_RESPONSE='{"time_regs":[]}'
cmd_time list --project 42 >/dev/null 2>&1 || true
_load_mock_state
assert_contains "project_id=42" "$LAST_API_PATH"

# --- time list with --per-page ---
_test "time list --per-page"
reset_mock
MOCK_API_RESPONSE='{"time_regs":[]}'
cmd_time list --per-page 50 >/dev/null 2>&1 || true
_load_mock_state
assert_contains "per_page=50" "$LAST_API_PATH"

# --- time list formatted output ---
_test "time list table output"
reset_mock
MOCK_API_RESPONSE='{"time_regs":[{"id":10,"date_worked":"2026-02-27","project_name":"Website","task_name":"Development","minutes":120,"notes":"Built feature","active":false}]}'
output=$(cmd_time list --date 2026-02-27)
assert_contains "ID" "$output"
assert_contains "DATE" "$output"
assert_contains "PROJECT" "$output"
assert_contains "TASK" "$output"
assert_contains "Website" "$output"
assert_contains "Development" "$output"

# --- time list active entry ---
_test "time list shows active indicator"
reset_mock
MOCK_API_RESPONSE='{"time_regs":[{"id":10,"date_worked":"2026-02-27","project_name":"Website","task_name":"Dev","minutes":30,"notes":null,"active":true}]}'
output=$(cmd_time list --date 2026-02-27)
assert_contains "***" "$output"

# --- time list raw ---
_test "time list --raw"
reset_mock
RAW=true
MOCK_API_RESPONSE='{"time_regs":[{"id":10}]}'
output=$(cmd_time list --date 2026-02-27)
assert_contains '"time_regs"' "$output"

# --- time show ---
_test "time show"
reset_mock
MOCK_API_RESPONSE='{"id":10,"minutes":120}'
output=$(cmd_time show 10)
_load_mock_state
assert_equals "GET" "$LAST_API_METHOD"
assert_equals "/time_regs/10" "$LAST_API_PATH"

# --- time show missing id ---
_test "time show requires ID"
reset_mock
output=$(cmd_time show 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- time create ---
_test "time create with all flags"
reset_mock
MOCK_API_RESPONSE='{"id":11,"minutes":90}'
cmd_time create --task 5 --minutes 90 --date 2026-02-20 --notes "Test" >/dev/null
_load_mock_state
assert_equals "POST" "$LAST_API_METHOD"
assert_equals "/time_regs" "$LAST_API_PATH"
assert_contains '"assigned_task_id": 5' "$LAST_API_BODY"
assert_contains '"minutes": 90' "$LAST_API_BODY"
assert_contains '"date_worked": "2026-02-20"' "$LAST_API_BODY"
assert_contains '"notes": "Test"' "$LAST_API_BODY"

# --- time create defaults ---
_test "time create defaults to 0 minutes and today"
reset_mock
MOCK_API_RESPONSE='{"id":12,"minutes":0}'
cmd_time create --task 5 >/dev/null
_load_mock_state
assert_contains '"minutes": 0' "$LAST_API_BODY"
assert_contains '"date_worked": "2026-02-27"' "$LAST_API_BODY"

# --- time create missing task ---
_test "time create requires --task"
reset_mock
output=$(cmd_time create 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Usage:" "$output"

# --- time update ---
_test "time update sends PATCH"
reset_mock
MOCK_API_RESPONSE='{"id":10,"minutes":60}'
cmd_time update 10 --minutes 60 --notes "Updated" >/dev/null
_load_mock_state
assert_equals "PATCH" "$LAST_API_METHOD"
assert_equals "/time_regs/10" "$LAST_API_PATH"
assert_contains '"minutes": 60' "$LAST_API_BODY"
assert_contains '"notes": "Updated"' "$LAST_API_BODY"

# --- time update missing id ---
_test "time update requires ID"
reset_mock
output=$(cmd_time update 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- time delete ---
_test "time delete"
reset_mock
MOCK_API_STATUS="204"
output=$(cmd_time delete 10)
_load_mock_state
assert_equals "DELETE" "$LAST_API_METHOD"
assert_equals "/time_regs/10" "$LAST_API_PATH"
assert_contains "Deleted." "$output"

# --- time delete missing id ---
_test "time delete requires ID"
reset_mock
output=$(cmd_time delete 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- time timer ---
_test "time timer sends PATCH to /timer"
reset_mock
MOCK_API_RESPONSE='{"id":10,"active":true}'
cmd_time timer 10 >/dev/null
_load_mock_state
assert_equals "PATCH" "$LAST_API_METHOD"
assert_equals "/time_regs/10/timer" "$LAST_API_PATH"

# --- time timer missing id ---
_test "time timer requires ID"
reset_mock
output=$(cmd_time timer 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"

# --- unknown action ---
_test "time unknown action"
reset_mock
output=$(cmd_time bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown time action" "$output"

_print_summary
