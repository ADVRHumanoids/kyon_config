#!/usr/bin/env bash
# connect-wg.bash — register this machine as a dynamic WireGuard peer on kyon-control
# Usage:
#   ./connect-wg.bash          # connect
#   ./connect-wg.bash down     # disconnect

set -euo pipefail

SERVER_SSH="kyon@kyon03-robot"
SERVER_WG_IFACE="wg0"
SERVER_WG_ADDR="10.0.0.1"
SERVER_WG_PORT="51820"
VPN_SUBNET="10.0.0"
KEY_DIR="$HOME/.wireguard"
CONF_FILE="/tmp/wg-kyon.conf"

# ── Guards ────────────────────────────────────────────────────────────────────
for cmd in wg wg-quick ssh sshpass; do
    command -v "$cmd" &>/dev/null || { echo "Required command not found: $cmd" >&2; exit 1; }
done

# ── Remote password (used for SSH login and sudo -S) ─────────────────────────
read -rsp "Password for $SERVER_SSH: " REMOTE_PASS
echo
SUDO_PASS="$REMOTE_PASS"

# ── Disconnect ────────────────────────────────────────────────────────────────
if [[ -f "$CONF_FILE" ]]; then
    LOCAL_PUBKEY=$(wg pubkey < "$KEY_DIR/kyon.key")
    echo "Removing peer from server..."
    echo "$SUDO_PASS" | sshpass -p "$REMOTE_PASS" ssh "$SERVER_SSH" "sudo -S -p '' wg set $SERVER_WG_IFACE peer $LOCAL_PUBKEY remove" || true
    sudo wg-quick down "$CONF_FILE"
    rm -f "$CONF_FILE"
    echo "Disconnected."
fi

if [[ "${1:-}" == "down" ]]; then
    exit 0;
fi

# ── Keypair ───────────────────────────────────────────────────────────────────
mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"
if [[ ! -f "$KEY_DIR/kyon.key" ]]; then
    echo "Generating WireGuard keypair in $KEY_DIR ..."
    wg genkey | tee "$KEY_DIR/kyon.key" | wg pubkey > "$KEY_DIR/kyon.pub"
    chmod 600 "$KEY_DIR/kyon.key"
    echo "  Public key: $(cat "$KEY_DIR/kyon.pub")"
fi
LOCAL_PRIVKEY=$(cat "$KEY_DIR/kyon.key")
LOCAL_PUBKEY=$(cat "$KEY_DIR/kyon.pub")

# ── Fetch server public key ───────────────────────────────────────────────────
# server.pub is world-readable (chmod 644) — no sudo needed.
echo "Connecting to $SERVER_SSH ..."
SERVER_PUBKEY=$(sshpass -p "$REMOTE_PASS" ssh "$SERVER_SSH" "cat /etc/wireguard/server.pub" | tr -d '\r')

# ── Pick next free VPN address (start from .10 to leave room for static peers) ─
USED_IPS=$(echo "$SUDO_PASS" | sshpass -p "$REMOTE_PASS" ssh "$SERVER_SSH" \
    "sudo -S -p '' wg show $SERVER_WG_IFACE allowed-ips 2>/dev/null \
     | awk '{print \$2}' | cut -d/ -f1" | tr -d '\r' || true)

VPN_IP=""
for i in $(seq 10 254); do
    candidate="${VPN_SUBNET}.${i}"
    if ! grep -qx "$candidate" <<< "$USED_IPS"; then
        VPN_IP="$candidate"
        break
    fi
done

[[ -n "$VPN_IP" ]] || { echo "No free VPN addresses available in ${VPN_SUBNET}.10-254" >&2; exit 1; }
echo "Assigned VPN address: $VPN_IP"

# ── Register dynamic peer on the server ──────────────────────────────────────
echo "$SUDO_PASS" | sshpass -p "$REMOTE_PASS" ssh "$SERVER_SSH" "sudo -S -p '' wg set $SERVER_WG_IFACE peer $LOCAL_PUBKEY allowed-ips ${VPN_IP}/32"
unset SUDO_PASS REMOTE_PASS
echo "Peer registered (non-persistent, cleared on server reboot)."

# ── Write local tunnel config ─────────────────────────────────────────────────
cat > "$CONF_FILE" <<EOF
[Interface]
Address    = ${VPN_IP}/24
PrivateKey = ${LOCAL_PRIVKEY}

[Peer]
PublicKey           = ${SERVER_PUBKEY}
Endpoint            = kyon03-robot:${SERVER_WG_PORT}
AllowedIPs          = 10.0.0.0/24, 10.24.15.0/24
PersistentKeepalive = 25
EOF
chmod 600 "$CONF_FILE"

# ── Bring up the tunnel ───────────────────────────────────────────────────────
sudo wg-quick up "$CONF_FILE"

echo ""
echo "Connected as $VPN_IP"
echo "  kyon-control   10.24.15.102  (${VPN_SUBNET}.1)"
echo "  amax-kyon-iit  10.24.15.100"
echo "  ed-power-board 10.24.15.200"
echo ""
echo "To disconnect:  $0 down"
