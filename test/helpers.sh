#!/usr/bin/env bash
# Test helpers: source CLI functions, mock _api, provide assertions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLI_PATH="$SCRIPT_DIR/../bin/stemplin"

# Counters
_PASS=0
_FAIL=0
_TEST_NAME=""

# Mock state
MOCK_API_RESPONSE=""
MOCK_API_STATUS="200"
LAST_API_METHOD=""
LAST_API_PATH=""
LAST_API_BODY=""

# Temp files to persist mock captures across subshells
_MOCK_DIR=$(mktemp -d)
trap 'rm -rf "$_MOCK_DIR"' EXIT

# Set env vars so need_var doesn't die during source
export STEMPLIN_URL="http://test.example.com"
export STEMPLIN_API_TOKEN="test-token-123"
export STEMPLIN_ORG_ID="1"

# Source CLI functions (the __TESTING__ guard prevents dispatch)
__TESTING__=1 source "$CLI_PATH"

# Override _api with mock
_api() {
  local method="$1" path="$2"
  shift 2
  local body=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --data) body="$2"; shift 2 ;;
      *)      shift ;;
    esac
  done

  # Write captures to separate files so they survive subshells
  echo "$method" > "$_MOCK_DIR/method"
  echo "$path" > "$_MOCK_DIR/path"
  echo "$body" > "$_MOCK_DIR/body"

  if [[ "$MOCK_API_STATUS" == "204" ]]; then
    echo "Deleted."
    return 0
  elif [[ "$MOCK_API_STATUS" == "401" ]]; then
    echo "Error: Unauthorized (401). Check STEMPLIN_API_TOKEN." >&2
    return 1
  elif [[ "$MOCK_API_STATUS" == "403" ]]; then
    echo "Error: Forbidden (403). You don't have access to this resource." >&2
    return 1
  elif [[ "$MOCK_API_STATUS" == "404" ]]; then
    echo "Error: Not found (404)." >&2
    return 1
  elif [[ "$MOCK_API_STATUS" == "422" ]]; then
    echo "Error: Validation error (422): $MOCK_API_RESPONSE" >&2
    return 1
  fi

  echo "$MOCK_API_RESPONSE"
}

# Load captured mock state from temp files into shell variables
_load_mock_state() {
  [[ -f "$_MOCK_DIR/method" ]] && LAST_API_METHOD=$(<"$_MOCK_DIR/method")
  [[ -f "$_MOCK_DIR/path" ]]   && LAST_API_PATH=$(<"$_MOCK_DIR/path")
  [[ -f "$_MOCK_DIR/body" ]]   && LAST_API_BODY=$(<"$_MOCK_DIR/body")
}

# Override _today for deterministic tests
_today() { echo "2026-02-27"; }

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

_test() {
  _TEST_NAME="$1"
}

assert_equals() {
  local expected="$1" actual="$2" desc="${3:-$_TEST_NAME}"
  if [[ "$expected" == "$actual" ]]; then
    _PASS=$(( _PASS + 1 ))
  else
    _FAIL=$(( _FAIL + 1 ))
    echo "  FAIL: $desc"
    echo "    expected: $(echo "$expected" | head -3)"
    echo "    actual:   $(echo "$actual" | head -3)"
  fi
}

assert_contains() {
  local needle="$1" haystack="$2" desc="${3:-$_TEST_NAME}"
  if echo "$haystack" | grep -qF -- "$needle"; then
    _PASS=$(( _PASS + 1 ))
  else
    _FAIL=$(( _FAIL + 1 ))
    echo "  FAIL: $desc"
    echo "    expected to contain: $needle"
    echo "    in: $(echo "$haystack" | head -5)"
  fi
}

assert_not_contains() {
  local needle="$1" haystack="$2" desc="${3:-$_TEST_NAME}"
  if ! echo "$haystack" | grep -qF -- "$needle"; then
    _PASS=$(( _PASS + 1 ))
  else
    _FAIL=$(( _FAIL + 1 ))
    echo "  FAIL: $desc"
    echo "    expected NOT to contain: $needle"
  fi
}

assert_matches() {
  local pattern="$1" haystack="$2" desc="${3:-$_TEST_NAME}"
  if echo "$haystack" | grep -qE -- "$pattern"; then
    _PASS=$(( _PASS + 1 ))
  else
    _FAIL=$(( _FAIL + 1 ))
    echo "  FAIL: $desc"
    echo "    expected to match: $pattern"
    echo "    in: $(echo "$haystack" | head -5)"
  fi
}

assert_exit_code() {
  local expected="$1"
  shift
  local actual=0
  "$@" >/dev/null 2>&1 || actual=$?
  assert_equals "$expected" "$actual" "${_TEST_NAME}: exit code"
}

# Reset mock state before each test
reset_mock() {
  MOCK_API_RESPONSE=""
  MOCK_API_STATUS="200"
  LAST_API_METHOD=""
  LAST_API_PATH=""
  LAST_API_BODY=""
  RAW=false
  rm -f "$_MOCK_DIR/method" "$_MOCK_DIR/path" "$_MOCK_DIR/body"
}

# Print summary at end
_print_summary() {
  local file_name
  file_name=$(basename "${BASH_SOURCE[1]}" .sh)
  local total=$(( _PASS + _FAIL ))
  if [[ $_FAIL -eq 0 ]]; then
    echo "  ${file_name}: ${total} tests, all passed"
  else
    echo "  ${file_name}: ${total} tests, ${_FAIL} FAILED"
  fi
  echo "${_PASS}:${_FAIL}"
}
