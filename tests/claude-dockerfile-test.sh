#!/usr/bin/env bash

set -euo pipefail

DOCKERFILE="$(cd "$(dirname "$0")/.." && pwd)/docker/claude-code/Dockerfile"

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

assert_contains "USER \$USERNAME"
assert_contains 'curl -fsSL https://claude.ai/install.sh | bash'
assert_contains "/home/\${USERNAME}/.local/bin"
assert_contains 'RUN claude --version'
assert_contains 'apt-get install -y build-essential lld mold protobuf-compiler'
assert_absent 'npm install -g @anthropic-ai/claude-code'

echo "Claude Dockerfile tests: OK"
