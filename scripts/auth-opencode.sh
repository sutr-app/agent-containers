#!/usr/bin/env bash

# Run OpenCode authentication with credentials stored on the host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/auth.sh
source "$SCRIPT_DIR/lib/auth.sh"

prepare_auth opencode opencode

echo "Starting OpenCode authentication. Follow the prompts to complete login."
docker run -it --rm \
    -v "$DATA_DIR:/home/codespace/.opencode" \
    "$IMAGE" "opencode auth login"
