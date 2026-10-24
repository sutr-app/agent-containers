# check=skip=FromPlatformFlagConstDisallowed
# Use --platform to enable emulation on ARM64 (M1/M2 Mac)
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/universal:linux

# Install the native Rust build toolchain, selectable linkers, protoc, and compiler cache.
RUN sudo apt-get update && sudo apt-get install -y build-essential lld mold protobuf-compiler sccache && sudo rm -rf /var/lib/apt/lists/*

# Install the latest OpenAI Codex CLI when the image is built.
# https://github.com/openai/codex
RUN npm install -g @openai/codex@latest && codex --version

# Use the same runtime user as the other agent images and the worktree owner.
ARG USERNAME=codespace
USER $USERNAME

# Install Rust for the non-root runtime user.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}" \
    RUSTC_WRAPPER=sccache \
    SCCACHE_DIR="/home/${USERNAME}/.cache/sccache" \
    CODEX_HOME="/home/${USERNAME}/.codex"

# CODEX_HOME points to the mounted config directory so auth.json / config.toml
# placed by the host are discovered automatically
RUN mkdir -p "$CODEX_HOME" "/home/${USERNAME}/.agents/skills"

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
