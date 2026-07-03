#!/usr/bin/env bash
# wg-show.bash — wrapper around `wg show` that replaces public keys with the
# comment on the line immediately above each [Peer] block in wg0.conf.
#
# Usage: sudo ./wg-show.bash [interface]   (default: wg0)

IFACE="${1:-wg0}"
CONF="/etc/wireguard/${IFACE}.conf"

# Build associative array: pubkey -> name from conf comments
declare -A NAMES
last_comment=""
while IFS= read -r line; do
    if [[ "$line" =~ ^#[[:space:]]*(.*) ]]; then
        last_comment="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^PublicKey[[:space:]]*=[[:space:]]*(.*) ]]; then
        key="${BASH_REMATCH[1]}"
        key="${key// /}"          # trim spaces
        [[ -n "$last_comment" ]] && NAMES["$key"]="$last_comment"
        last_comment=""
    else
        [[ -n "${line// /}" ]] && last_comment=""   # non-empty, non-comment resets
    fi
done < "$CONF"

# Run wg show and substitute known pubkeys
wg show "$IFACE" | while IFS= read -r line; do
    for key in "${!NAMES[@]}"; do
        if [[ "$line" == *"$key"* ]]; then
            line="${line//$key/${NAMES[$key]} ($key)}"
        fi
    done
    echo "$line"
done
