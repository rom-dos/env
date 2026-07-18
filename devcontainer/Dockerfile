# syntax=docker/dockerfile:1.7

# Based on Anthropic's Claude Code devcontainer template, with:
# - OpenCode installed
# - Passwordless sudo for the non-root user
# - NO firewall / network restrictions (internet enabled)
# - tmux installed

ARG UBUNTU_IMAGE=ubuntu:24.04@sha256:4fbb8e6a8395de5a7550b33509421a2bafbc0aab6c06ba2cef9ebffbc7092d90
FROM ${UBUNTU_IMAGE}

ARG TZ
ARG TARGETARCH
ARG NODE_VERSION=22.23.1
ARG CLAUDE_CODE_VERSION=2.1.214
ARG HUNKDIFF_VERSION=0.17.1
ARG OPENCODE_VERSION=1.18.3
ARG PNPM_VERSION=11.14.0
ARG STARSHIP_VERSION=1.26.0
ARG LAZYGIT_VERSION=0.63.1
ARG NVIM_VERSION=v0.12.4
ARG TPM_COMMIT=e261deb1b47614eed3400089ce7197dc68acc4eb
ARG PYTHON_VERSION=3.14.6
ENV TZ="${TZ}" \
  LANG=C.UTF-8 \
  LC_ALL=C.UTF-8

# Install common dev tools.
# Note: we intentionally do NOT install iptables/ipset or ship a firewall script.
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  apt-get update && apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  less \
  procps \
  sudo \
  zsh \
  zsh-syntax-highlighting \
  unzip \
  xz-utils \
  openssh-client \
  gh \
  jq \
  luarocks \
  tmux \
  nnn \
  ncurses-term \
  git \
  git-delta \
  fzf \
  ripgrep \
  zoxide \
  fd-find \
  && rm -rf /var/lib/apt/lists/*
RUN if command -v fdfind >/dev/null 2>&1 && [ ! -e /usr/local/bin/fd ]; then \
  ln -s /usr/bin/fdfind /usr/local/bin/fd; \
  fi

# Install the official Node distribution directly into the runtime base.
RUN case "${TARGETARCH}" in \
  amd64) node_arch=x64; node_sha=9749e988f437343b7fa832c69ded82a312e41a03116d766797ac14f6f9eee578 ;; \
  arm64) node_arch=arm64; node_sha=0294e8b915ab75f92c7513d2fcb830ae06e10684e6c603e99a87dbf8835389c1 ;; \
  *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" \
  -o /tmp/node.tar.xz \
  && echo "${node_sha}  /tmp/node.tar.xz" | sha256sum -c - \
  && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
  && rm /tmp/node.tar.xz \
  && node -v \
  && npm -v

# Install pinned global npm tools.
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global \
  NPM_CONFIG_FUND=false \
  NPM_CONFIG_AUDIT=false \
  NPM_CONFIG_UPDATE_NOTIFIER=false \
  NPM_CONFIG_PROGRESS=false \
  NPM_CONFIG_CACHE=/root/.npm \
  PATH="/usr/local/share/npm-global/bin:${PATH}"
RUN mkdir -p /usr/local/share/npm-global
RUN --mount=type=cache,target=/root/.npm \
  npm install -g \
  "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" \
  "hunkdiff@${HUNKDIFF_VERSION}" \
  "opencode-ai@${OPENCODE_VERSION}" \
  && corepack enable --install-directory /usr/local/share/npm-global/bin \
  && corepack prepare "pnpm@${PNPM_VERSION}" --activate

# Install the pinned Starship release.
RUN case "${TARGETARCH}" in \
  amd64) starship_target=x86_64-unknown-linux-gnu; starship_sha=321f0dd7af8340a5f2e6a8fec6538a04f617486f9ec70d878f91c09cd8deef22 ;; \
  arm64) starship_target=aarch64-unknown-linux-musl; starship_sha=dc30189378d2f2e287384e8a692d3f95ad1df64cf0e8c36aa9201516028aed6b ;; \
  *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/starship/starship/releases/download/v${STARSHIP_VERSION}/starship-${starship_target}.tar.gz" \
  -o /tmp/starship.tar.gz \
  && echo "${starship_sha}  /tmp/starship.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/starship.tar.gz -C /usr/local/bin starship \
  && rm /tmp/starship.tar.gz \
  && starship --version

# Ubuntu 24.04 does not package lazygit, so install its pinned release.
RUN case "${TARGETARCH}" in \
  amd64) lazygit_arch=x86_64; lazygit_sha=8e033bc78c8e192dee9510e951f6c9e154289b7198d22c924ed1d0a951b0dac1 ;; \
  arm64) lazygit_arch=arm64; lazygit_sha=555dbc9a8efcf2e33bc24e7fbd9463e9fa375e3c5e23cc270763733c38eeae36 ;; \
  *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${lazygit_arch}.tar.gz" \
  -o /tmp/lazygit.tar.gz \
  && echo "${lazygit_sha}  /tmp/lazygit.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit \
  && rm /tmp/lazygit.tar.gz \
  && lazygit --version

# Install the pinned Neovim release for the target architecture.
RUN case "${TARGETARCH}" in \
  amd64) nvim_arch=x86_64; nvim_sha=012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628 ;; \
  arm64) nvim_arch=arm64; nvim_sha=ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f ;; \
  *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${nvim_arch}.tar.gz" \
  -o /tmp/nvim.tar.gz \
  && echo "${nvim_sha}  /tmp/nvim.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/nvim.tar.gz -C /opt \
  && mv "/opt/nvim-linux-${nvim_arch}" /opt/nvim \
  && ln -s /opt/nvim/bin/nvim /usr/local/bin/nvim \
  && rm /tmp/nvim.tar.gz \
  && nvim --version

# Ensure git worktrees use relative paths by default.
RUN git config --system worktree.useRelativePaths true \
  && git config --system --add safe.directory /workspace

RUN if ! id -u "sbox" >/dev/null 2>&1; then \
  useradd -m -s /usr/bin/zsh "sbox"; \
  else \
  usermod -s /usr/bin/zsh "sbox"; \
  fi

# Ensure the default sbox user has access to the global npm prefix.
RUN mkdir -p /usr/local/share/npm-global \
  && chown -R "sbox:sbox" /usr/local/share

# Persist shell history across container rebuilds.
RUN mkdir -p /commandhistory \
  && touch /commandhistory/.bash_history /commandhistory/.zsh_history \
  && chown -R "sbox:sbox" /commandhistory \
  && cat >/etc/profile.d/00-commandhistory.sh <<'EOF'
# Persist interactive shell history in /commandhistory.
if [ -d /commandhistory ]; then
  export HISTSIZE=100000
  export HISTFILESIZE=200000

  if [ -n "${BASH_VERSION:-}" ]; then
    export HISTFILE=/commandhistory/.bash_history
    shopt -s histappend 2>/dev/null || true
    PROMPT_COMMAND="history -a; ${PROMPT_COMMAND:-}"
  fi

  if [ -n "${ZSH_VERSION:-}" ]; then
    export HISTFILE=/commandhistory/.zsh_history
    export SAVEHIST=200000
    setopt APPEND_HISTORY INC_APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS
  fi
fi
EOF

RUN echo '. /etc/profile.d/00-commandhistory.sh' >> /etc/bash.bashrc \
  && touch /etc/zsh/zshrc \
  && echo 'source /etc/profile.d/00-commandhistory.sh' >> /etc/zsh/zshrc

# Helpful marker for shell prompts / scripts.
ENV DEVCONTAINER=true

# Create workspace + agent config dirs and set permissions.
RUN mkdir -p /workspace /home/sbox/.claude /home/sbox/.npm /home/sbox/.config \
  && chown -R sbox:sbox /workspace /home/sbox/.claude /home/sbox/.npm /home/sbox/.config

WORKDIR /workspace

# Install global packages.
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH="${PATH}:/usr/local/share/npm-global/bin"
ENV NPM_CONFIG_FUND=false \
  NPM_CONFIG_AUDIT=false \
  NPM_CONFIG_UPDATE_NOTIFIER=false \
  NPM_CONFIG_PROGRESS=false

# Switch to non-root for normal dev.
USER sbox

# Runtime npm cache should be writable by sbox.
ENV NPM_CONFIG_CACHE=/home/sbox/.npm

# Default shell + editor.
ENV HOME=/home/sbox
ENV XDG_CONFIG_HOME=$HOME/.config
ENV SHELL=/usr/bin/zsh
ENV EDITOR=nvim
ENV VISUAL=nvim

# Install the shared application configurations.
RUN mkdir -p /home/sbox/.config \
  && curl -fsSL https://github.com/rom-dos/env/archive/refs/heads/master.tar.gz \
  | tar -xz --strip-components=3 -C /home/sbox/.config \
  env-master/home/.config

# Install the shared shell and tmux configurations and the tmux plugin manager.
RUN curl -fsSL https://raw.githubusercontent.com/rom-dos/env/master/home/.zprofile \
  -o /home/sbox/.zprofile \
  && curl -fsSL https://raw.githubusercontent.com/rom-dos/env/master/home/.tmux.conf \
  -o /home/sbox/.tmux.conf \
  && git clone --filter=blob:none https://github.com/tmux-plugins/tpm /home/sbox/.tmux/plugins/tpm \
  && git -C /home/sbox/.tmux/plugins/tpm checkout --detach "${TPM_COMMIT}"

# Install the pinned uv release.
COPY --from=ghcr.io/astral-sh/uv:0.11.29 /uv /bin/uv

# Ensure uv is on PATH for the sbox user.
ENV PATH="/home/sbox/.local/bin:${PATH}"

# Preinstall managed Python for uv.
RUN uv python install "${PYTHON_VERSION}"

# Passwordless sudo for the non-root user (for unattended / automation workflows).
USER root
RUN echo "sbox ALL=(root) NOPASSWD: ALL" > /etc/sudoers.d/yolo \
  && chmod 0440 /etc/sudoers.d/yolo

USER sbox
