#!/bin/sh
# /root/cek_status.sh  --  Router (Lain)  [debinet / Debian]
# Poin 5: bukti konfigurasi jaringan bertahan setelah reboot.
# Menampilkan ringkasan interface + status tabel NAT.

set -u

echo "=== cek_status.sh | $(hostname) | $(date '+%Y-%m-%d %H:%M:%S') ==="

echo
echo "--- ip -br a ---"
ip -br a

echo
echo "--- iptables -t nat -L -v -n ---"
iptables -t nat -L -v -n
