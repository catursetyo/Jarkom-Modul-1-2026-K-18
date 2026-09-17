#!/bin/sh
# /root/setup-ftp.sh  --  Chisa  [alpinet / Alpine]
# Poin 7: FTP server (vsftpd) untuk The Wired.
#   Shared folder : /var/wired/data
#   Log & config  : /var/wired (log)  |  /etc/vsftpd (config)
#   Akun FTP      : alice = read & write
#                   mika  = read-only (upload ditolak 550)
#                   eiri  = blacklist (login ditolak)
#   Password      : alice123 / mika123 / eiri123
#
# Jalankan SETELAH /root/setup-network.sh (butuh internet untuk `apk add`).

set -u

SHARE_DIR="/var/wired/data"
LOG_DIR="/var/wired"
FTP_DIR="/etc/vsftpd"
CONF="$FTP_DIR/vsftpd.conf"
USER_CONF_DIR="$FTP_DIR/user_conf"
USER_LIST="$FTP_DIR/user_list"
CHROOT_DIR="/var/wired/empty"

# --- 1. Pasang paket vsftpd ---
if ! command -v vsftpd >/dev/null 2>&1; then
    echo "[..] memasang vsftpd"
    apk add --no-cache vsftpd || { echo "[ERR] apk gagal - cek internet/NAT di Chisa"; exit 1; }
fi

# --- 2. Direktori bersama ---
mkdir -p "$SHARE_DIR" "$LOG_DIR" "$USER_CONF_DIR" "$CHROOT_DIR" /etc/pam.d
addgroup -S wired 2>/dev/null || true
chown root:wired "$LOG_DIR" "$SHARE_DIR"
chmod 2775 "$SHARE_DIR"
chmod 755 "$LOG_DIR" "$CHROOT_DIR"

# --- 3. Akun FTP ---
# /sbin/nologin didaftarkan di /etc/shells supaya tidak ditolak pemeriksaan shell.
grep -qx "/sbin/nologin" /etc/shells 2>/dev/null || echo "/sbin/nologin" >> /etc/shells

buat_akun() {
    _user="$1"
    _home="$2"
    if ! id "$_user" >/dev/null 2>&1; then
        adduser -D -H -h "$_home" -s /sbin/nologin -G wired "$_user"
    fi
    echo "$_user:${_user}123" | chpasswd
}

buat_akun alice "$SHARE_DIR"
buat_akun mika  "$SHARE_DIR"
buat_akun eiri  "$LOG_DIR"

# --- 4. Konfigurasi vsftpd ---
cat > "$CONF" <<'EOF'
# vsftpd -- Chisa | poin 7
listen=YES
listen_ipv6=NO

# hanya akun lokal, tanpa anonymous
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022

# setiap user dikurung di home-nya sendiri
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/wired/empty

# logging di /var/wired
xferlog_enable=YES
xferlog_file=/var/wired/xferlog.log
dual_log_enable=YES
vsftpd_log_file=/var/wired/vsftpd.log
use_localtime=YES

# blacklist: akun yang terdaftar di user_list ditolak saat login
userlist_enable=YES
userlist_deny=YES
userlist_file=/etc/vsftpd/user_list

# override per user (dipakai mika: read-only)
user_config_dir=/etc/vsftpd/user_conf

# kanal data PASV (dipakai pembuktian port data di poin 8)
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

pam_service_name=vsftpd
seccomp_sandbox=NO
EOF

# --- 5. Override mika (read-only) + blacklist eiri ---
cat > "$USER_CONF_DIR/mika" <<'EOF'
# mika: read-only -> STOR/DELE ditolak 550
write_enable=NO
EOF

echo "eiri" > "$USER_LIST"

# --- 6. PAM (hanya kalau image tidak menyediakannya) ---
if [ ! -f /etc/pam.d/vsftpd ]; then
    mkdir -p /etc/pam.d
    cat > /etc/pam.d/vsftpd <<'EOF'
auth    required pam_unix.so
account required pam_unix.so
session required pam_unix.so
EOF
fi

# --- 7. Jalankan service ---
if command -v rc-service >/dev/null 2>&1 && [ -d /run/openrc ]; then
    rc-update add vsftpd default >/dev/null 2>&1 || true
    rc-service vsftpd restart >/dev/null 2>&1 || rc-service vsftpd start >/dev/null 2>&1 || true
else
    killall vsftpd 2>/dev/null || true
    sleep 1
    vsftpd "$CONF" &
    sleep 1
fi

# --- 8. Laporan ---
echo
if pidof vsftpd >/dev/null 2>&1; then
    echo "[OK] vsftpd jalan (pid: $(pidof vsftpd))"
else
    echo "[ERR] vsftpd tidak jalan - cek /var/wired/vsftpd.log"
fi

echo "[OK] shared folder : $SHARE_DIR"
echo "[OK] akun          : alice (rw) | mika (ro) | eiri (blacklist)"
echo "[i]  uji cepat     : ftp 192.220.2.2   (kalau perintah ftp tidak ada: apk add --no-cache inetutils-ftp)"
