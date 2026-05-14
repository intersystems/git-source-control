FROM node:20

ARG TZ
ENV TZ="$TZ"

ARG CLAUDE_CODE_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    less git procps sudo fzf zsh man-db unzip gnupg2 gh \
    iptables ipset iproute2 dnsutils aggregate jq nano vim \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/local/share/npm-global && \
    chown -R node:node /usr/local/share

ARG USERNAME=node

RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.bash_history \
    && chown -R $USERNAME /commandhistory

ENV DEVCONTAINER=true

RUN mkdir -p /workspace /home/node/.claude && \
    chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
    wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
    rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

USER node

ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV SHELL=/bin/zsh
ENV EDITOR=nano
ENV VISUAL=nano

ARG ZSH_IN_DOCKER_VERSION=1.2.0
RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
    -p git \
    -p fzf \
    -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
    -a "source /usr/share/doc/fzf/examples/completion.zsh" \
    -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
    -x

RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Playwright CLI for headless browser automation against the IRIS portal.
# Chromium is installed at build time because the Playwright CDN is not
# on the runtime firewall allowlist.
RUN npm install -g @playwright/cli@latest playwright
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/share/playwright-browsers
USER root
RUN npx playwright install --with-deps chrome && \
    chmod -R o+rx /usr/local/share/playwright-browsers
USER node

# Firewall and entrypoint scripts (build context is .devcontainer/)
COPY --chown=root:root init-firewall.sh /usr/local/bin/init-firewall.sh
COPY --chown=root:root workspace/workspace-entrypoint.sh /workspace-entrypoint.sh
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh /workspace-entrypoint.sh

ENTRYPOINT ["/workspace-entrypoint.sh"]
