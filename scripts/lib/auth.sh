#!/usr/bin/env bash

set -euo pipefail

REGISTRY="ghcr.io/sutr-app"

default_data_dir() {
    local agent="$1"

    case "$(uname -s)" in
        Darwin)
            printf '%s\n' "$HOME/Library/Application Support/agent-container-spec/$agent"
            ;;
        Linux)
            printf '%s\n' "$HOME/.local/share/agent-container-spec/$agent"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            printf '%s\n' "$APPDATA/agent-container-spec/$agent"
            ;;
        *)
            echo "Unsupported OS: $(uname -s)" >&2
            exit 1
            ;;
    esac
}

prepare_auth() {
    local agent="$1"
    local image_name="$2"

    IMAGE_TAG="${IMAGE_TAG:-${VERSION:-}}"
    if [ -z "$IMAGE_TAG" ]; then
        echo "Set IMAGE_TAG or VERSION to the published image version." >&2
        exit 1
    fi

    DATA_DIR="${DATA_DIR:-$(default_data_dir "$agent")}" 
    IMAGE="${IMAGE:-$REGISTRY/$image_name:$IMAGE_TAG}"

    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker is not installed or not in PATH." >&2
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "Docker daemon is not running." >&2
        exit 1
    fi

    mkdir -p "$DATA_DIR"

    if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
        echo "Docker image '$IMAGE' was not found locally." >&2
        echo "Authenticate to the registry if required, then run:" >&2
        echo "  docker pull '$IMAGE'" >&2
        exit 1
    fi
}
