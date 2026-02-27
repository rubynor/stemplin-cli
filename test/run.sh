#!/usr/bin/env bash
# Test runner: finds and executes all test_*.sh files, reports totals
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

total_pass=0
total_fail=0
failed_files=()

echo "Running stemplin-cli tests..."
echo ""

for test_file in "$SCRIPT_DIR"/test_*.sh; do
  [[ -f "$test_file" ]] || continue

  # Run the test file, capture last line (pass:fail counts)
  output=$(bash "$test_file" 2>&1) || true
  last_line=$(echo "$output" | tail -1)

  # Print everything except the last line (the counts)
  echo "$output" | sed '$d'

  # Parse pass:fail from last line
  if [[ "$last_line" =~ ^([0-9]+):([0-9]+)$ ]]; then
    total_pass=$(( total_pass + ${BASH_REMATCH[1]} ))
    total_fail=$(( total_fail + ${BASH_REMATCH[2]} ))
    [[ ${BASH_REMATCH[2]} -gt 0 ]] && failed_files+=("$(basename "$test_file")")
  fi
done

echo ""
echo "================================"
echo "Total: $(( total_pass + total_fail )) tests, ${total_pass} passed, ${total_fail} failed"

if [[ ${#failed_files[@]} -gt 0 ]]; then
  echo "Failed in: ${failed_files[*]}"
fi

echo "================================"

[[ $total_fail -eq 0 ]]
