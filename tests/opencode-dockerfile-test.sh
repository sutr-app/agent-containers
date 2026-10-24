#!/usr/bin/env bash

set -euo pipefail

DOCKERFILE="$(cd "$(dirname "$0")/.." && pwd)/docker/opencode/Dockerfile"

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

assert_contains 'npm install -g opencode-ai@latest'
assert_contains 'apt-get install -y build-essential lld mold protobuf-compiler'
assert_absent 'ARG OPENCODE_VERSION='

echo "OpenCode Dockerfile tests: OK"
