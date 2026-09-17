#!/bin/sh

set -eu

echo "[*] Menyiapkan OpenSSH Server di Knights..."

if ! command -v sshd >/dev/null 2>&1; then
    echo "[*] Memasang openssh..."
    apk add --no-cache openssh
fi

if ! id mika_admin >/dev/null 2>&1; then
    echo "[*] Membuat akun mika_admin..."
    adduser -D -s /bin/sh mika_admin
    passwd -d mika_admin || true
fi

mkdir -p /home/mika_admin/.ssh
touch /home/mika_admin/.ssh/authorized_keys
chmod 700 /home/mika_admin/.ssh
chmod 600 /home/mika_admin/.ssh/authorized_keys
chown -R mika_admin:mika_admin /home/mika_admin/.ssh

SSHD_CONFIG="/etc/ssh/sshd_config"

sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' "$SSHD_CONFIG"

grep -q "^PasswordAuthentication no" "$SSHD_CONFIG" || echo "PasswordAuthentication no" >> "$SSHD_CONFIG"
grep -q "^PubkeyAuthentication yes" "$SSHD_CONFIG" || echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"

ssh-keygen -A

killall sshd 2>/dev/null || true
/usr/sbin/sshd

echo ""
echo "[OK] OpenSSH Server Knights siap!"
echo "     Port                 : 22"
echo "     User                 : mika_admin"
echo "     PasswordAuth         : no"
echo "     PubkeyAuth           : yes"
echo "     Authorized Keys File : /home/mika_admin/.ssh/authorized_keys"
