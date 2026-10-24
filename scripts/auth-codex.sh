#!/usr/bin/env bash

# Run Codex authentication with credentials stored on the host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/auth.sh
source "$SCRIPT_DIR/lib/auth.sh"

HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
if [ "$HOST_UID" -eq 0 ]; then
    echo "Run this script as a non-root host user so Codex does not run as root." >&2
    exit 1
fi

prepare_auth codex openai-codex

LOGIN_ARGS="${CODEX_LOGIN_ARGS---device-auth}"
echo "Starting Codex authentication. Follow the prompts to complete login."
docker run -it --rm \
    --user "$HOST_UID:$HOST_GID" \
    -e HOME=/tmp \
    -e RUSTUP_HOME=/home/codespace/.rustup \
    -e CARGO_HOME=/tmp/.cargo \
    -e SCCACHE_DIR=/tmp/.cache/sccache \
    -v "$DATA_DIR:/home/codespace/.codex" \
    "$IMAGE" "codex login $LOGIN_ARGS"
