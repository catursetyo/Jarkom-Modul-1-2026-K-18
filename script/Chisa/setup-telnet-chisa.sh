#!/bin/sh
# ==============================================================================
# Setup Telnet Server di Node Chisa (The Wired)
# Subnet: 192.220.2.0/24 | IP Chisa: 192.220.2.2
# ==============================================================================

set -eu

echo "[*] Menyiapkan layanan Telnet di Chisa..."

# 1. Pastikan paket busybox-extras terpasang jika telnetd belum tersedia
if ! command -v telnetd >/dev/null 2>&1; then
    echo "[*] Memasang busybox-extras (telnetd)..."
    apk add --no-cache busybox-extras
fi

# 2. Buat user phantom_user jika belum ada
if ! id phantom_user >/dev/null 2>&1; then
    echo "[*] Membuat akun phantom_user..."
    adduser -D -s /bin/sh phantom_user
fi

# 3. Set password user phantom_user menjadi wired_ghost
echo "phantom_user:wired_ghost" | chpasswd
echo "[*] Password untuk phantom_user berhasil disetel ke wired_ghost."

# 4. Hentikan instance telnetd lama jika ada, lalu jalankan daemon telnetd baru
killall telnetd 2>/dev/null || true

# Jalankan telnetd pada port 23
telnetd -p 23

# Verifikasi port 23 LISTEN
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
