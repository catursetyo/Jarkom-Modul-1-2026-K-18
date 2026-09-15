#!/bin/sh
# /root/setup-network.sh  --  Mika  [alpinet / Alpine]
# Switch1 - subnet 192.220.1.0/24

set -u

IFACE="eth0"
IPADDR="192.220.1.3/24"
GATEWAY="192.220.1.1"
DNS_SERVER="8.8.8.8"

ip link set "$IFACE" up
ip addr flush dev "$IFACE"
ip addr add "$IPADDR" dev "$IFACE"
ip route replace default via "$GATEWAY" dev "$IFACE"
echo "nameserver $DNS_SERVER" > /etc/resolv.conf

echo "[OK] Mika network configured."
ip -br a
