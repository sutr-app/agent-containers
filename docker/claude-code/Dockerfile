# check=skip=FromPlatformFlagConstDisallowed
# Use --platform to enable emulation on ARM64 (M1/M2 Mac)
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/universal:linux

# Install the native Rust build toolchain, selectable linkers, protoc, and compiler cache.
RUN sudo apt-get update && sudo apt-get install -y build-essential lld mold protobuf-compiler sccache && sudo rm -rf /var/lib/apt/lists/*

# Use existing codespace user (UID/GID 1000) from base image
# Claude Code refuses to run with --dangerously-skip-permissions as root
ARG USERNAME=codespace

USER $USERNAME

# Install the native Claude Code binary in the runtime user's home directory.
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.cargo/bin:${PATH}" \
    RUSTC_WRAPPER=sccache \
    SCCACHE_DIR="/home/${USERNAME}/.cache/sccache"
RUN claude --version

# Install Rust for the non-root user
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Create directories for Claude Code config
RUN mkdir -p /home/$USERNAME/.claude

# Copy settings.json for jobworkerp-workflow-plugin support (Phase 3)
COPY settings.json /home/$USERNAME/.claude/settings.json

WORKDIR /workspace

# Default entrypoint uses shell to support piping
ENTRYPOINT ["/bin/sh", "-c"]
