#!/bin/sh

set -u

echo "=== cek_status.sh | $(hostname) | $(date '+%Y-%m-%d %H:%M:%S') ==="

echo
echo "--- ip -br a ---"
ip -br a

echo
echo "--- iptables -t nat -L -v -n ---"
iptables -t nat -L -v -n
