#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

FAKE_BIN="$TEMP_DIR/bin"
DOCKER_LOG="$TEMP_DIR/docker.log"
mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOCKER_LOG"

case "$1" in
  info)
    exit "${FAKE_DOCKER_INFO_STATUS:-0}"
    ;;
  image)
    [ "$2" = "inspect" ] && [ "${FAKE_IMAGE_EXISTS:-1}" = 1 ]
    ;;
  run)
    exit 0
    ;;
esac
EOF
chmod +x "$FAKE_BIN/docker"

cat > "$FAKE_BIN/id" <<'EOF'
#!/usr/bin/env bash

case "$1" in
  -u)
    printf '%s\n' "${FAKE_ID_UID:?}"
    ;;
  -g)
    printf '%s\n' "${FAKE_ID_GID:?}"
    ;;
  *)
    echo "Unexpected id argument: $1" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$FAKE_BIN/id"

assert_contains() {
    local expected="$1"

    if ! grep -Fq -- "$expected" "$DOCKER_LOG"; then
        echo "Expected Docker invocation to contain: $expected" >&2
        exit 1
    fi
}

invoke_auth() {
    local agent="$1"
    shift

    env -u IMAGE -u IMAGE_TAG -u VERSION -u CODEX_LOGIN_ARGS \
        DATA_DIR="$TEMP_DIR/$agent" DOCKER_LOG="$DOCKER_LOG" \
        FAKE_ID_UID=1234 FAKE_ID_GID=5678 FAKE_IMAGE_EXISTS=1 FAKE_DOCKER_INFO_STATUS=0 \
        PATH="$FAKE_BIN:$PATH" "$@" bash "$ROOT/scripts/auth-$agent.sh"
}

assert_not_started() {
    if grep -Fq -- 'run ' "$DOCKER_LOG"; then
        echo "Authentication failure must not start a container" >&2
        exit 1
    fi
}

assert_failure() {
    local expected="$1"
    shift

    : > "$DOCKER_LOG"
    if invoke_auth codex "$@" >"$TEMP_DIR/error.log" 2>&1; then
        echo "Expected authentication to fail: $expected" >&2
        exit 1
    fi
    if ! grep -Fq -- "$expected" "$TEMP_DIR/error.log"; then
        echo "Expected authentication error: $expected" >&2
        cat "$TEMP_DIR/error.log" >&2
        exit 1
    fi
    assert_not_started
}

run_auth_script() {
    local agent="$1"
    local image="$2"
    local container_path="$3"
    local login_command="$4"
    local data_dir="$TEMP_DIR/$agent"

    : > "$DOCKER_LOG"
    invoke_auth "$agent" IMAGE_TAG=20260712_0 >/dev/null

    assert_contains "image inspect $image"
    assert_contains "-v $data_dir:$container_path"
    assert_contains "$image $login_command"
}

run_auth_script claude \
    ghcr.io/sutr-app/claude-code:20260712_0 \
    /home/codespace/.claude \
    "claude --dangerously-skip-permissions"

run_auth_script codex \
    ghcr.io/sutr-app/openai-codex:20260712_0 \
    /home/codespace/.codex \
    "codex login --device-auth"

assert_contains "run -it --rm --user 1234:5678 -e HOME=/tmp -e RUSTUP_HOME=/home/codespace/.rustup -e CARGO_HOME=/tmp/.cargo -e SCCACHE_DIR=/tmp/.cache/sccache -v $TEMP_DIR/codex:/home/codespace/.codex"

run_auth_script opencode \
    ghcr.io/sutr-app/opencode:20260712_0 \
    /home/codespace/.opencode \
    "opencode auth login"

: > "$DOCKER_LOG"
invoke_auth codex IMAGE_TAG=20260712_0 IMAGE=example.com/custom/codex:override >/dev/null
assert_contains 'image inspect example.com/custom/codex:override'
assert_contains 'example.com/custom/codex:override codex login --device-auth'

: > "$DOCKER_LOG"
invoke_auth codex VERSION=20260713_0 >/dev/null
assert_contains 'ghcr.io/sutr-app/openai-codex:20260713_0 codex login --device-auth'

: > "$DOCKER_LOG"
invoke_auth codex IMAGE_TAG=20260712_0 VERSION=20260713_0 >/dev/null
assert_contains 'ghcr.io/sutr-app/openai-codex:20260712_0 codex login --device-auth'

: > "$DOCKER_LOG"
invoke_auth codex IMAGE_TAG= VERSION=20260713_0 >/dev/null
assert_contains 'ghcr.io/sutr-app/openai-codex:20260713_0 codex login --device-auth'

assert_failure 'Set IMAGE_TAG or VERSION'
assert_failure 'Set IMAGE_TAG or VERSION' IMAGE_TAG= VERSION=
assert_failure "Docker image 'ghcr.io/sutr-app/openai-codex:20260712_0' was not found locally." \
    IMAGE_TAG=20260712_0 FAKE_IMAGE_EXISTS=0
assert_contains 'image inspect ghcr.io/sutr-app/openai-codex:20260712_0'
assert_failure 'Docker daemon is not running.' IMAGE_TAG=20260712_0 FAKE_DOCKER_INFO_STATUS=1
assert_failure 'Run this script as a non-root host user' IMAGE_TAG=20260712_0 FAKE_ID_UID=0 FAKE_ID_GID=0

echo "Authentication script tests: OK"
