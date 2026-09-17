#!/bin/sh

set -u

SHARE_DIR="/var/wired/data"
LOG_DIR="/var/wired"
FTP_DIR="/etc/vsftpd"
CONF="$FTP_DIR/vsftpd.conf"
USER_CONF_DIR="$FTP_DIR/user_conf"
USER_LIST="$FTP_DIR/user_list"
CHROOT_DIR="/var/wired/empty"

if ! command -v vsftpd >/dev/null 2>&1; then
    echo "[..] memasang vsftpd"
    apk add --no-cache vsftpd || { echo "[ERR] apk gagal - cek internet/NAT di Chisa"; exit 1; }
fi

mkdir -p "$SHARE_DIR" "$LOG_DIR" "$USER_CONF_DIR" "$CHROOT_DIR" /etc/pam.d
addgroup -S wired 2>/dev/null || true
chown root:wired "$LOG_DIR" "$SHARE_DIR"
chmod 2775 "$SHARE_DIR"
chmod 755 "$LOG_DIR" "$CHROOT_DIR"

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

cat > "$CONF" <<'EOF'
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
chroot_local_user=YES
allow_writeable_chroot=YES
secure_chroot_dir=/var/wired/empty
xferlog_enable=YES
xferlog_file=/var/wired/xferlog.log
dual_log_enable=YES
vsftpd_log_file=/var/wired/vsftpd.log
use_localtime=YES
userlist_enable=YES
userlist_deny=YES
userlist_file=/etc/vsftpd/user_list
user_config_dir=/etc/vsftpd/user_conf
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100
pam_service_name=vsftpd
seccomp_sandbox=NO
EOF

cat > "$USER_CONF_DIR/mika" <<'EOF'
write_enable=NO
EOF

echo "eiri" > "$USER_LIST"

if [ ! -f /etc/pam.d/vsftpd ]; then
    mkdir -p /etc/pam.d
    cat > /etc/pam.d/vsftpd <<'EOF'
auth    required pam_unix.so
account required pam_unix.so
session required pam_unix.so
EOF
fi

if command -v rc-service >/dev/null 2>&1 && [ -d /run/openrc ]; then
    rc-update add vsftpd default >/dev/null 2>&1 || true
    rc-service vsftpd restart >/dev/null 2>&1 || rc-service vsftpd start >/dev/null 2>&1 || true
else
    killall vsftpd 2>/dev/null || true
    sleep 1
    vsftpd "$CONF" &
    sleep 1
fi

echo
if pidof vsftpd >/dev/null 2>&1; then
    echo "[OK] vsftpd jalan (pid: $(pidof vsftpd))"
else
    echo "[ERR] vsftpd tidak jalan - cek /var/wired/vsftpd.log"
fi

echo "[OK] shared folder : $SHARE_DIR"
echo "[OK] akun          : alice (rw) | mika (ro) | eiri (blacklist)"
echo "[i]  uji cepat     : ftp 192.220.2.2   (kalau perintah ftp tidak ada: apk add --no-cache inetutils-ftp)"
