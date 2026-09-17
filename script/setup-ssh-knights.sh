#!/bin/sh
# ==============================================================================
# Setup OpenSSH Server di Node Knights (The Wired) - Soal 13
# Subnet: 192.220.3.0/24 | IP Knights: 192.220.3.2
# ==============================================================================

set -eu

echo "[*] Menyiapkan OpenSSH Server di Knights..."

# 1. Pasang paket openssh jika belum ada
if ! command -v sshd >/dev/null 2>&1; then
    echo "[*] Memasang openssh..."
    apk add --no-cache openssh
fi

# 2. Buat user mika_admin jika belum ada
if ! id mika_admin >/dev/null 2>&1; then
    echo "[*] Membuat akun mika_admin..."
    adduser -D -s /bin/sh mika_admin
    # Kunci password lokal agar hanya bisa login via SSH Public Key
    passwd -d mika_admin || true
fi

# 3. Siapkan direktori .ssh dan file authorized_keys
mkdir -p /home/mika_admin/.ssh
touch /home/mika_admin/.ssh/authorized_keys
chmod 700 /home/mika_admin/.ssh
chmod 600 /home/mika_admin/.ssh/authorized_keys
chown -R mika_admin:mika_admin /home/mika_admin/.ssh

# 4. Konfigurasi sshd_config (Wajib: PasswordAuthentication no & PubkeyAuthentication yes)
SSHD_CONFIG="/etc/ssh/sshd_config"

# Pastikan opsi-opsi penting diatur dengan benar
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' "$SSHD_CONFIG"

# Jika opsi belum ada di file konfigurasi, tambahkan di akhir
grep -q "^PasswordAuthentication no" "$SSHD_CONFIG" || echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
grep -q "^PubkeyAuthentication yes" "$SSHD_CONFIG" || echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"

# 5. Generate host keys jika belum ada
ssh-keygen -A

# 6. Jalankan ulang daemon sshd
killall sshd 2>/dev/null || true
/usr/sbin/sshd

echo ""
echo "[OK] OpenSSH Server Knights siap!"
echo "     Port                 : 22"
echo "     User                 : mika_admin"
echo "     PasswordAuth         : no"
echo "     PubkeyAuth           : yes"
echo "     Authorized Keys File : /home/mika_admin/.ssh/authorized_keys"
