#!/bin/bash
set -euo pipefail

# Set up firewall as root (requires NET_ADMIN capability).
# This runs at every container start, before any user processes.
/usr/local/bin/init-firewall.sh

# --- SSH client setup: wait for key from iris container ---

SHARED_KEY="/workspace/.devcontainer/.ssh/dev_key"
NODE_SSH_DIR="/home/node/.ssh"
NODE_KEY="${NODE_SSH_DIR}/dev_key"
NODE_CONFIG="${NODE_SSH_DIR}/config"

echo "Waiting for SSH key from iris container..."
while [ ! -f "$SHARED_KEY" ]; do
    sleep 1
done

mkdir -p "$NODE_SSH_DIR"
cp "$SHARED_KEY" "$NODE_KEY"
chown node:node "$NODE_SSH_DIR" "$NODE_KEY"
chmod 700 "$NODE_SSH_DIR"
chmod 600 "$NODE_KEY"

cat > "$NODE_CONFIG" <<'SSHEOF'
Host iris
    User irisowner
    IdentityFile ~/.ssh/dev_key
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
SSHEOF
chown node:node "$NODE_CONFIG"
chmod 600 "$NODE_CONFIG"

echo "SSH client configured."

# Drop to the node user and exec the container command (e.g., "sleep infinity").
# This ensures user processes never run as root.
# Strip NET_ADMIN and NET_RAW from the bounding set so user processes cannot
# modify iptables rules or craft raw packets to bypass the firewall.
exec setpriv --reuid=node --regid=node --init-groups \
    --bounding-set=-net_admin,-net_raw \
    --ambient-caps=-net_admin,-net_raw \
    -- "$@"
