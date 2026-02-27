#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/rubynor/stemplin-cli/main"

BIN_DIR="$HOME/bin"
SKILL_DIR="$HOME/.claude/skills"
COMPLETION_DIR="${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions}"
ZSH_COMPLETION_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions"
RC_FILE="$HOME/.stemplinrc"

info()  { echo "  -> $*"; }
ok()    { echo "  [ok] $*"; }
warn()  { echo "  [!] $*"; }

# Detect if running from a local checkout or via curl pipe
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null || echo ".")" && pwd)"
LOCAL=false
if [[ -f "$SCRIPT_DIR/bin/stemplin" ]]; then
  LOCAL=true
fi

fetch_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if $LOCAL; then
    cp "$SCRIPT_DIR/$src" "$dest"
  else
    curl -sSL "$REPO_RAW/$src" -o "$dest"
  fi
}

echo "Installing stemplin CLI..."
echo ""

# 1. CLI binary
mkdir -p "$BIN_DIR"
fetch_file "bin/stemplin" "$BIN_DIR/stemplin"
chmod +x "$BIN_DIR/stemplin"
ok "CLI installed to $BIN_DIR/stemplin"

# 2. Claude skill
mkdir -p "$SKILL_DIR"
fetch_file "skill/stemplin-api.md" "$SKILL_DIR/stemplin-api.md"
ok "Claude skill installed to $SKILL_DIR/stemplin-api.md"

# 3. Bash completions
mkdir -p "$COMPLETION_DIR"
fetch_file "completions/stemplin.bash" "$COMPLETION_DIR/stemplin"
ok "Bash completions installed to $COMPLETION_DIR/stemplin"

# 3b. Zsh completions
mkdir -p "$ZSH_COMPLETION_DIR"
fetch_file "completions/stemplin.zsh" "$ZSH_COMPLETION_DIR/_stemplin"
ok "Zsh completions installed to $ZSH_COMPLETION_DIR/_stemplin"

# 4. Config file
if [[ ! -f "$RC_FILE" ]]; then
  echo ""
  read -rp "Create ~/.stemplinrc with your API config? [Y/n] " answer
  if [[ "${answer:-Y}" =~ ^[Yy]$ ]]; then
    read -rp "  STEMPLIN_URL (e.g. https://stemplin.com): " url
    read -rp "  STEMPLIN_API_TOKEN: " token
    read -rp "  STEMPLIN_ORG_ID (optional, press Enter to skip): " org_id

    cat > "$RC_FILE" <<EOF
export STEMPLIN_URL="${url}"
export STEMPLIN_API_TOKEN="${token}"
export STEMPLIN_ORG_ID="${org_id}"
EOF
    chmod 600 "$RC_FILE"
    ok "Config saved to $RC_FILE"
  fi
else
  info "Config already exists at $RC_FILE"
fi

# 5. PATH check
echo ""
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
  warn "$BIN_DIR is not in your PATH. Add this to your shell profile:"
  echo "    export PATH=\"\$HOME/bin:\$PATH\""
fi

echo ""
echo "Done! Run 'stemplin help' to get started."
