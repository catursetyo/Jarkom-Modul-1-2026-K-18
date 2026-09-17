#!/bin/sh

set -eu

echo "[*] Menyiapkan layanan di Knights (Port 22 & Port 80)..."

if ! command -v sshd >/dev/null 2>&1; then
    echo "[*] Memasang openssh..."
    apk add --no-cache openssh
fi

ssh-keygen -A

killall sshd 2>/dev/null || true
/usr/sbin/sshd

mkdir -p /var/www/html
cat <<'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>Knights Web Node</title></head>
<body><h1>Knights of the Wired</h1><p>Active Service Node 192.220.3.2</p></body>
</html>
EOF

killall httpd 2>/dev/null || true
httpd -p 80 -h /var/www/html

killall -9 $(netstat -tlpn 2>/dev/null | grep ":7777 " | awk '{print $7}' | cut -d'/' -f1) 2>/dev/null || true

echo ""
echo "[*] Status port pada Knights:"
netstat -tlpn | grep -E ":(22|80|7777) " || true

echo ""
echo "[OK] Layanan siap untuk dipindai dari Alice:"
echo "     Port 22 (SSH)  : TERBUKA (LISTEN)"
echo "     Port 80 (HTTP) : TERBUKA (LISTEN)"
echo "     Port 7777      : TERTUTUP (NO LISTENER)"
