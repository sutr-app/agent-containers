#!/usr/bin/env bash

set -euo pipefail

WORKFLOW="$(cd "$(dirname "$0")/.." && pwd)/.github/workflows/publish-images.yml"

assert_contains() {
    local expected="$1"

    if ! grep -Fq -- "$expected" "$WORKFLOW"; then
        echo "Expected workflow to contain: $expected" >&2
        exit 1
    fi
}

assert_contains 'pull: true'
assert_contains 'no-cache: true'

echo "Publish workflow tests: OK"
