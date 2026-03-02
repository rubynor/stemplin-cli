#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/helpers.sh"

# ---------------------------------------------------------------------------
# Mock curl for update tests
# ---------------------------------------------------------------------------
# The real curl is needed by _api (mocked separately), but cmd_update calls
# curl directly.  We override curl with a function that returns canned
# responses based on the URL being fetched.

MOCK_REMOTE_VERSION="$VERSION"   # default: same as local (up to date)
MOCK_CURL_FAIL=false

curl() {
  if $MOCK_CURL_FAIL; then
    return 1
  fi

  local url=""
  local outfile=""
  local args=("$@")
  for ((i = 0; i < ${#args[@]}; i++)); do
    case "${args[i]}" in
      -o) outfile="${args[i+1]}"; ((i++)) ;;
      http*) url="${args[i]}" ;;
    esac
  done

  case "$url" in
    */bin/stemplin)
      local content='#!/usr/bin/env bash
set -euo pipefail

VERSION="'"$MOCK_REMOTE_VERSION"'"
'
      if [[ -n "$outfile" ]]; then
        echo "$content" > "$outfile"
      else
        echo "$content"
      fi
      ;;
    */skill/stemplin-api.md)
      if [[ -n "$outfile" ]]; then
        echo "# mock skill" > "$outfile"
      fi
      ;;
    */completions/stemplin.bash)
      if [[ -n "$outfile" ]]; then
        echo "# mock completions" > "$outfile"
      fi
      ;;
    *)
      echo "mock curl: unexpected URL: $url" >&2
      return 1
      ;;
  esac
}

# Override mkdir/chmod/mv to avoid filesystem side effects
_UPDATE_LOG=""
mkdir() { _UPDATE_LOG="${_UPDATE_LOG}mkdir $*; "; }
chmod() { _UPDATE_LOG="${_UPDATE_LOG}chmod $*; "; }
mv() { _UPDATE_LOG="${_UPDATE_LOG}mv $*; "; }

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

# --- Already up to date ---
_test "update: already up to date"
MOCK_REMOTE_VERSION="$VERSION"
output=$(cmd_update 2>&1)
assert_contains "Already up to date" "$output"
assert_contains "v${VERSION}" "$output"

# --- --check with no update ---
_test "update --check: no update available"
MOCK_REMOTE_VERSION="$VERSION"
output=$(cmd_update --check 2>&1)
assert_contains "Already up to date" "$output"

# --- --check with update available ---
_test "update --check: update available"
MOCK_REMOTE_VERSION="9.9.9"
output=$(cmd_update --check 2>&1)
assert_contains "Update available" "$output"
assert_contains "v${VERSION}" "$output"
assert_contains "v9.9.9" "$output"

# --- Successful update ---
_test "update: successful update"
MOCK_REMOTE_VERSION="9.9.9"
_UPDATE_LOG=""
output=$(cmd_update 2>&1)
assert_contains "Updating stemplin" "$output"
assert_contains "v${VERSION} -> v9.9.9" "$output"
assert_contains "Updated to v9.9.9" "$output"

# --- curl failure ---
_test "update: curl failure"
MOCK_CURL_FAIL=true
output=$(cmd_update 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Failed to download" "$output"
MOCK_CURL_FAIL=false

# --- Unknown flag ---
_test "update: unknown flag"
output=$(cmd_update --bogus 2>&1) && rc=0 || rc=$?
assert_equals "1" "$rc"
assert_contains "Unknown flag" "$output"

# --- Help topic ---
_test "help update shows usage"
output=$(cmd_help update)
assert_contains "stemplin update" "$output"
assert_contains "--check" "$output"

_print_summary
