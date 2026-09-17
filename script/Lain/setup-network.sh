#!/bin/sh

set -u

UPLINK_IF="eth0"
UPLINK_IP="192.168.122.2/24"
UPLINK_GW="192.168.122.1"
DNS_SERVER="8.8.8.8"

LAN="eth1:192.220.1.1/24 eth2:192.220.2.1/24 eth3:192.220.3.1/24"

ip link set "$UPLINK_IF" up
ip addr flush dev "$UPLINK_IF"
ip addr add "$UPLINK_IP" dev "$UPLINK_IF"
ip route replace default via "$UPLINK_GW" dev "$UPLINK_IF"
echo "nameserver $DNS_SERVER" > /etc/resolv.conf

for entry in $LAN; do
    iface="${entry%%:*}"
    addr="${entry#*:}"
    ip link set "$iface" up
    ip addr flush dev "$iface"
    ip addr add "$addr" dev "$iface"
done

echo 1 > /proc/sys/net/ipv4/ip_forward

if ! iptables -t nat -C POSTROUTING -o "$UPLINK_IF" -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o "$UPLINK_IF" -j MASQUERADE
fi

echo "[OK] Router network configured."
ip -br a
