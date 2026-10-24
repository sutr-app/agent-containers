#!/usr/bin/env bash

# Run Claude Code authentication with credentials stored on the host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/auth.sh
source "$SCRIPT_DIR/lib/auth.sh"

prepare_auth claude claude-code

CLAUDE_JSON="$DATA_DIR/.claude.json"
if [ ! -f "$CLAUDE_JSON" ]; then
    printf '{}\n' > "$CLAUDE_JSON"
fi

echo "Starting Claude Code authentication. Follow the prompts to complete auth."
docker run -it --rm \
    -v "$DATA_DIR:/home/codespace/.claude" \
    -v "$CLAUDE_JSON:/home/codespace/.claude.json" \
    "$IMAGE" "claude --dangerously-skip-permissions"
