#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Reset policies to ACCEPT first so that on container restarts (where policies may already
# be DROP from a prior run) the script can still make outbound connections (e.g. curl GitHub).
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 1. Extract Docker DNS info BEFORE any flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Flush all existing rules and ipsets
iptables -F; iptables -X
iptables -t nat -F; iptables -t nat -X
iptables -t mangle -F; iptables -t mangle -X
ipset destroy allowed-domains 2>/dev/null || ipset flush allowed-domains 2>/dev/null || true

# 2. Selectively restore ONLY internal Docker DNS resolution
if [ -n "$DOCKER_DNS_RULES" ]; then
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | xargs -L 1 iptables -t nat
fi

# Allow DNS (outbound UDP 53 + inbound responses)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT  -p udp --sport 53 -j ACCEPT
# Allow inter-container traffic (SSH and IRIS web server) by resolving
# peer container IPs.  Rules that don't match a local listener are no-ops.
for peer in iris workspace; do
    PEER_IP=$(getent hosts "$peer" | awk '{print $1}') || continue
    iptables -A OUTPUT -p tcp -d "$PEER_IP" --dport 22    -j ACCEPT
    iptables -A OUTPUT -p tcp -d "$PEER_IP" --dport 52773 -j ACCEPT
    iptables -A INPUT  -p tcp -s "$PEER_IP" --dport 22    -j ACCEPT
done
# Allow localhost
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Create ipset (hash:net supports CIDRs)
ipset create --exist allowed-domains hash:net

# Add GitHub IP ranges (from api.github.com/meta, .web + .api + .git, aggregated)
gh_ranges=$(curl -s https://api.github.com/meta)
echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q | while read -r cidr; do
    ipset add --exist allowed-domains "$cidr"
done

# Resolve and add specific allowed domains
# AWS Bedrock endpoints — read region from environment, fall back to us-east-1
AWS_REGION="${AWS_DEFAULT_REGION:-${AWS_REGION:-us-east-1}}"
for domain in "registry.npmjs.org" "api.anthropic.com" "sentry.io" \
    "statsig.anthropic.com" "statsig.com" \
    "marketplace.visualstudio.com" "vscode.blob.core.windows.net" \
    "update.code.visualstudio.com" \
    "docs.intersystems.com" \
    "bedrock-runtime.${AWS_REGION}.amazonaws.com" \
    "bedrock.${AWS_REGION}.amazonaws.com" \
    "sts.amazonaws.com" "sts.${AWS_REGION}.amazonaws.com"; do
    ips=$(dig +noall +answer A "$domain" | awk '$4 == "A" {print $5}')
    while read -r ip; do
        ipset add --exist allowed-domains "$ip"
    done < <(echo "$ips")
done

# Default-deny policies
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  DROP

# Allow established/related first
iptables -A INPUT  -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow outbound to whitelisted IPs only
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Reject everything else with immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

# Verification: must NOT reach example.com, MUST reach api.github.com
curl --connect-timeout 5 https://example.com >/dev/null 2>&1 && exit 1   # should fail
curl --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1 || exit 1  # must succeed
echo "Firewall configuration complete"
