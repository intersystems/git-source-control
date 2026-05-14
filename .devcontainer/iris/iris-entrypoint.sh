#!/bin/bash
set -euo pipefail

# This entrypoint runs as root. It sets up the firewall and SSH, then drops
# to irisowner with NET_ADMIN/NET_RAW stripped from the bounding set.

# Apply outbound firewall before IRIS starts making network connections.
/usr/local/bin/init-firewall.sh

# Allow incoming connections to the IRIS web server. This port is published in
# docker-compose.yml for the management portal. On Docker Desktop for Windows the
# forwarded traffic can arrive from an IP outside the Docker bridge subnet, so
# this rule accepts from any source.
iptables -I INPUT 1 -p tcp --dport 52773 -j ACCEPT

# --- SSH setup: generate keypair and start sshd ---

SSH_DIR="/home/irisowner/dev/git-source-control/.devcontainer/.ssh"
PRIV_KEY="${SSH_DIR}/dev_key"
PUB_KEY="${SSH_DIR}/dev_key.pub"
AUTH_KEYS="/home/irisowner/.ssh/authorized_keys"

# Generate keypair on the shared volume if it doesn't already exist.
if [ ! -f "$PRIV_KEY" ]; then
    mkdir -p "$SSH_DIR"
    ssh-keygen -t ed25519 -f "$PRIV_KEY" -N "" -C "devcontainer-inter-container"
    chown -R irisowner:irisowner "$SSH_DIR"
fi

# Install the public key for irisowner.
mkdir -p /home/irisowner/.ssh
cp "$PUB_KEY" "$AUTH_KEYS"
chown -R irisowner:irisowner /home/irisowner/.ssh
chmod 700 /home/irisowner/.ssh
chmod 600 "$AUTH_KEYS"

# Start sshd as a background daemon.
/usr/sbin/sshd

# Drop to irisowner and strip NET_ADMIN/NET_RAW from the bounding set so
# IRIS processes cannot modify iptables rules or craft raw packets.
exec setpriv --reuid=irisowner --regid=irisowner --init-groups \
    --bounding-set=-net_admin,-net_raw \
    --ambient-caps=-net_admin,-net_raw \
    -- /tini -- /iris-main "$@"
