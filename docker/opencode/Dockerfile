# check=skip=FromPlatformFlagConstDisallowed
# Use --platform to enable emulation on ARM64 (M1/M2 Mac)
FROM --platform=linux/amd64 mcr.microsoft.com/devcontainers/universal:linux

# Install the native Rust build toolchain, selectable linkers, protoc, and compiler cache.
RUN sudo apt-get update && sudo apt-get install -y build-essential lld mold protobuf-compiler sccache && sudo rm -rf /var/lib/apt/lists/*

# Install the latest OpenCode CLI when the image is built.
RUN npm install -g opencode-ai@latest

# Use existing codespace user (UID/GID 1000) from base image
ARG USERNAME=codespace
USER $USERNAME

# Install Rust (universal image does not include Rust by default)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}" \
    RUSTC_WRAPPER=sccache \
    SCCACHE_DIR="/home/${USERNAME}/.cache/sccache"

# Fetch jobworkerp-workflow skill from upstream repository (always latest)
ARG SKILL_REPO=https://github.com/jobworkerp-rs/jobworkerp-workflow-plugin.git
ARG SKILL_BRANCH=main
RUN git clone --depth 1 --branch ${SKILL_BRANCH} ${SKILL_REPO} /tmp/jobworkerp-workflow-plugin \
    && mkdir -p /home/${USERNAME}/.opencode/skills \
    && cp -r /tmp/jobworkerp-workflow-plugin/skills/jobworkerp-workflow /home/${USERNAME}/.opencode/skills/ \
    && rm -rf /tmp/jobworkerp-workflow-plugin

WORKDIR /workspace

# Default entrypoint uses shell to support piping
ENTRYPOINT ["/bin/sh", "-c"]
