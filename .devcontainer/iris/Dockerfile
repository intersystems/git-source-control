ARG BASE=containers.intersystems.com/intersystems/iris-community:2025.1

FROM ${BASE}

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    git nodejs npm \
    iptables ipset iproute2 dnsutils aggregate curl jq \
    openssh-server \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN ssh-keygen -A && \
    mkdir -p /run/sshd && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

RUN --mount=type=bind,src=.,dst=/home/irisowner/dev/git-source-control/,rw \
    chown -R irisowner:irisowner /home/irisowner/dev/git-source-control/ && \
    su - irisowner -c "iris start iris" && \
    su - irisowner -c "iris session IRIS < /home/irisowner/dev/git-source-control/iris.script" && \
    su - irisowner -c "iris stop iris quietly"

COPY .devcontainer/init-firewall.sh /usr/local/bin/init-firewall.sh
COPY .devcontainer/iris/iris-entrypoint.sh /iris-entrypoint.sh
RUN chmod +x /usr/local/bin/init-firewall.sh /iris-entrypoint.sh

# Entrypoint runs as root to set up firewall and SSH, then drops to irisowner.
ENTRYPOINT ["/iris-entrypoint.sh"]
