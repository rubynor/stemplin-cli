#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# --- reports show formatted ---
_test "reports show formatted output"
reset_mock
MOCK_API_RESPONSE='{
  "total_minutes": 480,
  "total_entries": 5,
  "by_project": [
    {"project_name":"Website","client_name":"Acme","total_minutes":300,"total_entries":3},
    {"project_name":"App","client_name":"Beta","total_minutes":180,"total_entries":2}
  ],
  "by_user": [
    {"user_name":"Alice","total_minutes":300,"total_entries":3},
    {"user_name":"Bob","total_minutes":180,"total_entries":2}
  ]
}'
output=$(cmd_reports show)
_load_mock_state
assert_contains "Total: 8:00 (5 entries)" "$output"
assert_contains "By Project:" "$output"
assert_contains "Website" "$output"
assert_contains "Acme" "$output"
assert_contains "By User:" "$output"
assert_contains "Alice" "$output"
assert_contains "Bob" "$output"
assert_equals "GET" "$LAST_API_METHOD"

# --- reports show with filters ---
_test "reports show --from --to builds query string"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":0,"total_entries":0,"by_project":[],"by_user":[]}'
cmd_reports show --from 2026-01-01 --to 2026-01-31 >/dev/null
_load_mock_state
assert_contains "start_date=2026-01-01" "$LAST_API_PATH"
assert_contains "end_date=2026-01-31" "$LAST_API_PATH"

# --- reports show --clients --projects --users --tasks ---
_test "reports show all filter flags"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":0,"total_entries":0,"by_project":[],"by_user":[]}'
cmd_reports show --clients 1,2 --projects 3 --users 4,5 --tasks 6 >/dev/null
_load_mock_state
assert_contains "client_ids=1,2" "$LAST_API_PATH"
assert_contains "project_ids=3" "$LAST_API_PATH"
assert_contains "user_ids=4,5" "$LAST_API_PATH"
assert_contains "task_ids=6" "$LAST_API_PATH"

# --- reports show raw ---
_test "reports show --raw"
reset_mock
RAW=true
MOCK_API_RESPONSE='{"total_minutes":480,"total_entries":5,"by_project":[],"by_user":[]}'
output=$(cmd_reports show)
assert_contains '"total_minutes":480' "$output"

# --- reports detailed formatted ---
_test "reports detailed formatted output"
reset_mock
MOCK_API_RESPONSE='{
  "total_minutes": 480,
  "total_billable_minutes": 360,
  "dates": [
    {
      "date": "2025-10-15",
      "time_regs": [
        {"id":1,"date_worked":"2025-10-15","client_name":"Acme","project_name":"Website","task_name":"Development","notes":"Homepage work","user_name":"Mario","minutes":120,"project_billable":true,"rate":15000,"billed_amount":30000.0},
        {"id":2,"date_worked":"2025-10-15","client_name":"Acme","project_name":"Website","task_name":"Design","notes":"Logo","user_name":"Alice","minutes":60,"project_billable":true,"rate":15000,"billed_amount":15000.0}
      ]
    },
    {
      "date": "2025-10-14",
      "time_regs": [
        {"id":3,"date_worked":"2025-10-14","client_name":"Beta","project_name":"App","task_name":"Development","notes":"API work","user_name":"Bob","minutes":300,"project_billable":false,"rate":0,"billed_amount":0}
      ]
    }
  ]
}'
output=$(cmd_reports detailed)
_load_mock_state
assert_contains "Total: 8:00" "$output"
assert_contains "Billable: 6:00" "$output"
assert_contains "DATE" "$output"
assert_contains "CLIENT" "$output"
assert_contains "PROJECT" "$output"
assert_contains "TASK" "$output"
assert_contains "PERSON" "$output"
assert_contains "HOURS" "$output"
assert_contains "Acme" "$output"
assert_contains "Website" "$output"
assert_contains "Development" "$output"
assert_contains "Mario" "$output"
assert_contains "Alice" "$output"
assert_contains "Bob" "$output"
assert_contains "2025-10-15" "$output"
assert_contains "2025-10-14" "$output"
assert_equals "GET" "$LAST_API_METHOD"
assert_contains "/reports/detailed" "$LAST_API_PATH"

# --- reports detailed with filters ---
_test "reports detailed --from --to builds query string"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":0,"total_billable_minutes":0,"dates":[]}'
cmd_reports detailed --from 2025-10-01 --to 2026-03-02 >/dev/null
_load_mock_state
assert_contains "/reports/detailed" "$LAST_API_PATH"
assert_contains "start_date=2025-10-01" "$LAST_API_PATH"
assert_contains "end_date=2026-03-02" "$LAST_API_PATH"

# --- reports detailed all filter flags ---
_test "reports detailed all filter flags"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":0,"total_billable_minutes":0,"dates":[]}'
cmd_reports detailed --clients 95 --projects 122 --users 55,54 --tasks 155 >/dev/null
_load_mock_state
assert_contains "client_ids=95" "$LAST_API_PATH"
assert_contains "project_ids=122" "$LAST_API_PATH"
assert_contains "user_ids=55,54" "$LAST_API_PATH"
assert_contains "task_ids=155" "$LAST_API_PATH"

# --- reports detailed raw ---
_test "reports detailed --raw"
reset_mock
RAW=true
MOCK_API_RESPONSE='{"total_minutes":480,"total_billable_minutes":360,"dates":[]}'
output=$(cmd_reports detailed)
assert_contains '"total_billable_minutes":360' "$output"
assert_contains '"dates"' "$output"

# --- reports detailed truncates long notes ---
_test "reports detailed truncates long notes"
reset_mock
MOCK_API_RESPONSE='{
  "total_minutes": 60,
  "total_billable_minutes": 60,
  "dates": [
    {
      "date": "2025-10-15",
      "time_regs": [
        {"id":1,"date_worked":"2025-10-15","client_name":"Acme","project_name":"Website","task_name":"Dev","notes":"This is a very long note that should be truncated after thirty characters","user_name":"Mario","minutes":60,"project_billable":true,"rate":15000,"billed_amount":15000.0}
      ]
    }
  ]
}'
output=$(cmd_reports detailed)
assert_contains "This is a very long note that ..." "$output"
assert_not_contains "truncated after thirty characters" "$output"

# --- reports detailed missing billable falls back to 0 ---
_test "reports detailed missing billable_minutes defaults to 0"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":60,"dates":[]}'
output=$(cmd_reports detailed)
assert_contains "Billable: 0:00" "$output"

# --- reports detailed empty dates ---
_test "reports detailed with no entries"
reset_mock
MOCK_API_RESPONSE='{"total_minutes":0,"total_billable_minutes":0,"dates":[]}'
output=$(cmd_reports detailed)
assert_contains "Total: 0:00" "$output"
assert_contains "Billable: 0:00" "$output"

# --- reports unknown action ---
_test "reports unknown action"
reset_mock
output=$(cmd_reports bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown reports action" "$output"

_print_summary
