#!/bin/sh

set -eu

echo "[*] Menyiapkan layanan Telnet di Chisa..."

if ! command -v telnetd >/dev/null 2>&1; then
    echo "[*] Memasang busybox-extras (telnetd)..."
    apk add --no-cache busybox-extras
fi

if ! id phantom_user >/dev/null 2>&1; then
    echo "[*] Membuat akun phantom_user..."
    adduser -D -s /bin/sh phantom_user
fi

echo "phantom_user:wired_ghost" | chpasswd
echo "[*] Password untuk phantom_user berhasil disetel ke wired_ghost."

killall telnetd 2>/dev/null || true

telnetd -p 23

sleep 1
if netstat -tlpn 2>/dev/null | grep -q ":23 "; then
    echo "[OK] telnetd berhasil berjalan pada port 23 (LISTEN)"
elif ss -tlpn 2>/dev/null | grep -q ":23 "; then
    echo "[OK] telnetd berhasil berjalan pada port 23 (LISTEN)"
else
    echo "[!] Peringatan: telnetd mungkin belum berjalan sempurna, cek ps."
fi

echo "[*] Kredensial Telnet Chisa:"
echo "    Host     : 192.220.2.2"
echo "    Port     : 23"
echo "    User     : phantom_user"
echo "    Password : wired_ghost"
