#!/usr/bin/env bash

set -euo pipefail

DOCKERFILE="$(cd "$(dirname "$0")/.." && pwd)/docker/openai-codex/Dockerfile"
ENTRYPOINT_SCRIPT="$(dirname "$DOCKERFILE")/entrypoint.sh"
README="$(cd "$(dirname "$0")/.." && pwd)/README.md"

assert_contains() {
    local expected="$1"

    if ! grep -Fq -- "$expected" "$DOCKERFILE"; then
        echo "Expected Dockerfile to contain: $expected" >&2
        exit 1
    fi
}

assert_absent() {
    local unexpected="$1"

    if grep -Fq -- "$unexpected" "$DOCKERFILE"; then
        echo "Dockerfile must not contain: $unexpected" >&2
        exit 1
    fi
}

assert_entrypoint_contains() {
    local expected="$1"

    if ! grep -Fq -- "$expected" "$ENTRYPOINT_SCRIPT"; then
        echo "Expected entrypoint to contain: $expected" >&2
        exit 1
    fi
}

assert_entrypoint_absent() {
    local unexpected="$1"

    if grep -Fq -- "$unexpected" "$ENTRYPOINT_SCRIPT"; then
        echo "Entrypoint must not contain: $unexpected" >&2
        exit 1
    fi
}

assert_readme_contains() {
    local expected="$1"

    if ! grep -Fq -- "$expected" "$README"; then
        echo "Expected README to contain: $expected" >&2
        exit 1
    fi
}

assert_contains 'npm install -g @openai/codex@latest'
assert_contains 'apt-get install -y build-essential lld mold protobuf-compiler sccache'
assert_contains 'ARG USERNAME=codespace'
assert_contains "USER \$USERNAME"
assert_contains "CODEX_HOME=\"/home/\${USERNAME}/.codex\""
assert_contains "SCCACHE_DIR=\"/home/\${USERNAME}/.cache/sccache\""
assert_absent '/root/.codex'
assert_entrypoint_contains "SKILLS_BASE=\"\${HOME}/.agents/skills\""
assert_entrypoint_contains "CACHE_DIR=\"\${CODEX_HOME}/skill-cache\""
assert_entrypoint_absent '/root/.codex'
assert_readme_contains "  --user \"\$(id -u):\$(id -g)\""
assert_readme_contains '  -e HOME=/tmp'
assert_readme_contains '  -e RUSTUP_HOME=/home/codespace/.rustup'
assert_readme_contains '  -e CARGO_HOME=/tmp/.cargo'
assert_readme_contains '  -e SCCACHE_DIR=/tmp/.cache/sccache'
assert_absent 'ARG CODEX_VERSION='
assert_absent "npm install -g @openai/codex@\${CODEX_VERSION}"

echo "Codex Dockerfile tests: OK"
