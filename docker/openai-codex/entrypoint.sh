#!/bin/bash
# Fetch/update jobworkerp-workflow skill on every container start.
# Codex discovers skills from $HOME/.agents/skills/ hierarchy.
#
# Cache is stored below CODEX_HOME so it persists across container restarts
# when the Codex configuration directory is volume-mounted.

SKILLS_BASE="${HOME}/.agents/skills"
CACHE_DIR="${CODEX_HOME}/skill-cache"
REPO_URL="https://github.com/jobworkerp-rs/jobworkerp-workflow-plugin.git"
PLUGIN_REF="${WORKFLOW_PLUGIN_REF:-main}"

mkdir -p "$SKILLS_BASE"

if [ -d "$CACHE_DIR/.git" ]; then
    echo "Updating jobworkerp-workflow skill (ref: $PLUGIN_REF)..."
    if git -C "$CACHE_DIR" fetch origin "$PLUGIN_REF" --depth 1; then
        git -C "$CACHE_DIR" reset --hard FETCH_HEAD
    else
        echo "WARNING: Failed to fetch skill update. Using cached version." >&2
    fi
else
    echo "Cloning jobworkerp-workflow skill (ref: $PLUGIN_REF)..."
    rm -rf "$CACHE_DIR"
    if git clone --depth 1 --branch "$PLUGIN_REF" --sparse "$REPO_URL" "$CACHE_DIR"; then
        cd "$CACHE_DIR" && git sparse-checkout set skills
    else
        echo "ERROR: Failed to clone jobworkerp-workflow skill. Codex will run without workflow skill." >&2
    fi
fi

# Symlink so Codex sees $HOME/.agents/skills/jobworkerp-workflow/SKILL.md
if [ -d "$CACHE_DIR/skills/jobworkerp-workflow" ]; then
    ln -sfn "$CACHE_DIR/skills/jobworkerp-workflow" "$SKILLS_BASE/jobworkerp-workflow"
else
    echo "WARNING: skills/jobworkerp-workflow directory not found in cache. Codex will run without workflow skill." >&2
fi

# Execute the provided command
exec /bin/sh -c "$@"
