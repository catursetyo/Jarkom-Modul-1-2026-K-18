# JARKOM MODUL 1 2026 - K-18

## Member

| Nama | NRP |
| --- | --- |
| Catur Setyo Ragil | 5027251066 |
| Senna Bagus Harimurti | 5027251106 |

---

## Daftar Isi

- [Topologi & Addressing](#topologi--addressing)
- [Laporan Praktikum](#laporan-praktikum)
  - [1. Pembangunan Topologi Jaringan](#1-pembangunan-topologi-jaringan)
  - [2. Koneksi Internet Router (Lain)](#2-koneksi-internet-router-lain)
  - [3. Routing Antar Subnet (Semua Client Terhubung)](#3-routing-antar-subnet-semua-client-terhubung)
  - [4. Firewall Masquerade & DNS Resolver per Client](#4-firewall-masquerade--dns-resolver-per-client)
  - [5. Persistensi Konfigurasi Reboot & cek_status.sh](#5-persistensi-konfigurasi-reboot--cek_statussh)
  - [6. Traffic Generator di Mika & Analisis Wireshark](#6-traffic-generator-di-mika--analisis-wireshark)
  - [7. FTP Server vsFTPd di Chisa (The Wired)](#7-ftp-server-vsftpd-di-chisa-the-wired)
  - [8. Praktik FTP Client dari Knights (Upload via Alice)](#8-praktik-ftp-client-dari-knights-upload-via-alice)
  - [9. Download FTP oleh Mika & Bukti Read-Only 550](#9-download-ftp-oleh-mika--bukti-read-only-550)
  - [10–20. Status Pengerjaan Lanjutan](#1020-status-pengerjaan-lanjutan)

---

## Topologi & Addressing

Sesuai tema *Serial Experiments Lain*, entitas **Lain** bertindak sebagai **Router**, sedangkan entitas lainnya (**Alice, Mika, Chisa, Knights, Eiri**) bertindak sebagai **Client**. Jaringan dibagi ke dalam 3 switch dengan alokasi prefix IP kelompok **K-18** (`192.220.0.0/16`).

```
                 Internet
                    │
                 [ NAT1 ]
                    │ eth0 192.168.122.2/24 (gw 192.168.122.1)
              ┌─────────────┐
              │  Lain       │  router, image debinet
              │  (Router)   │  ip_forward=1 + MASQUERADE
              └─┬────┬───┬──┘
        eth1 .1.1│eth2│.2.1│eth3 .3.1
             SW1 │    │SW2 │SW3
        ┌────────┴┐ ┌─┴──┐┌┴──────────┐
      Alice    Mika Chisa Knights  Eiri
```

### Tabel Pengalamatan Node

| Node | Peran | Image OS | Switch | Interface | IP Address | Gateway | DNS |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Lain** | Router | `ardhptr21/debinet:latest` (Debian) | — | eth0<br>eth1<br>eth2<br>eth3 | `192.168.122.2/24`<br>`192.220.1.1/24`<br>`192.220.2.1/24`<br>`192.220.3.1/24` | `192.168.122.1` (eth0) | `8.8.8.8` |
| **Alice** | Client | `ardhptr21/alpinet:latest` (Alpine) | SW1 | eth0 | `192.220.1.2/24` | `192.220.1.1` | `8.8.8.8` |
| **Mika** | Client | `ardhptr21/alpinet:latest` (Alpine) | SW1 | eth0 | `192.220.1.3/24` | `192.220.1.1` | `8.8.8.8` |
| **Chisa** | Client | `ardhptr21/alpinet:latest` (Alpine) | SW2 | eth0 | `192.220.2.2/24` | `192.220.2.1` | `8.8.8.8` |
| **Knights** | Client | `ardhptr21/alpinet:latest` (Alpine) | SW3 | eth0 | `192.220.3.2/24` | `192.220.3.1` | `8.8.8.8` |
| **Eiri** | Client | `ardhptr21/alpinet:latest` (Alpine) | SW3 | eth0 | `192.220.3.3/24` | `192.220.3.1` | `8.8.8.8` |

---

## Laporan Praktikum

### 1. Pembangunan Topologi Jaringan

Untuk menghubungkan entitas di The Wired, **Lain** yang berperan sebagai Router dikonfigurasikan terhubung ke 3 Switch:
- **Switch 1**: Menghubungkan client **Alice** dan **Mika** (Subnet `192.220.1.0/24`).
- **Switch 2**: Menghubungkan client **Chisa** (Subnet `192.220.2.0/24`).
- **Switch 3**: Menghubungkan client **Knights** dan **Eiri** (Subnet `192.220.3.0/24`).

![](assets/01-topologi.png)

Topologi dibangun di GNS3 dengan rincian komponen:
1. **NAT1**: Node cloud bawaan GNS3 sebagai pintu gerbang menuju jaringan internet nyata (segmen `192.168.122.0/24`).
2. **Router Lain**: Container berbasis Debian (`ardhptr21/debinet:latest`) dengan 4 interface:
   - `eth0` menuju NAT1.
   - `eth1` menuju Switch 1.
   - `eth2` menuju Switch 2.
   - `eth3` menuju Switch 3.
3. **Ethernet Switch (SW1, SW2, SW3)**: Switch generic L2 bawaan GNS3.
4. **Client Nodes (Alice, Mika, Chisa, Knights, Eiri)**: Container berbasis Alpine Linux (`ardhptr21/alpinet:latest`).

---

### 2. Koneksi Internet Router (Lain)

Agar Router Lain dapat terhubung ke internet luar, interface `eth0` dikonfigurasikan agar terhubung ke segmen NAT1 (`192.168.122.0/24`).

Karena image `debinet` merupakan container minimalis yang tidak menyertakan daemon DHCP client (`dhclient` / `ifupdown`), konfigurasi jaringan diterapkan secara statis menggunakan perintah POSIX `ip` pada script `/root/setup-network.sh`:

```sh
# Konfigurasi uplink eth0 ke NAT1 pada Router Lain
ip link set eth0 up
ip addr flush dev eth0
ip addr add 192.168.122.2/24 dev eth0
ip route replace default via 192.168.122.1 dev eth0
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

**Penjelasan Perintah:**
- `ip link set eth0 up`: Mengaktifkan antarmuka fisik `eth0`.
- `ip addr flush dev eth0`: Menghapus alokasi IP lama/residu agar tidak terjadi multi-IP collision.
- `ip addr add 192.168.122.2/24 dev eth0`: Menetapkan IP address statik pada subnet NAT1.
- `ip route replace default via 192.168.122.1 dev eth0`: Mengarahkan default gateway ke IP gateway NAT1 (`192.168.122.1`).
- `echo "nameserver 8.8.8.8" > /etc/resolv.conf`: Menyetel resolver DNS Google agar router dapat menyelesaikan domain internet.

**Verifikasi Konektivitas Router:**
Pengujian dilakukan dengan melakukan ping ke gateway NAT, DNS publik, serta uji resolusi domain:

```sh
ping -c 3 192.168.122.1
ping -c 3 8.8.8.8
nslookup google.com
```

![](assets/02-router-inet.png)

Hasil pengujian membuktikan Router Lain dapat berkomunikasi secara normal dengan jaringan luar (0% packet loss).

---

### 3. Routing Antar Subnet (Semua Client Terhubung)

Agar kelima client dapat saling bertukar data lintas subnet yang berbeda, Router Lain harus mengaktifkan packet forwarding (`ip_forward`) dan masing-masing client harus memiliki alamat IP serta gateway yang mengarah ke interface router pada switch yang bersangkutan.

#### A. Konfigurasi Interface LAN & Forwarding di Router Lain

Pada script `/root/setup-network.sh` di Router Lain, interface `eth1`, `eth2`, dan `eth3` ditetapkan sebagai gateway untuk masing-masing subnet:

```sh
# Alokasi IP interface ke tiap switch
ip link set eth1 up && ip addr flush dev eth1 && ip addr add 192.220.1.1/24 dev eth1
ip link set eth2 up && ip addr flush dev eth2 && ip addr add 192.220.2.1/24 dev eth2
ip link set eth3 up && ip addr flush dev eth3 && ip addr add 192.220.3.1/24 dev eth3

# Mengaktifkan IPv4 packet forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
```

Perintah `echo 1 > /proc/sys/net/ipv4/ip_forward` memastikan kernel Linux diizinkan meneruskan paket antar-interface (routing layer 3).

#### B. Konfigurasi di Masing-masing Client

Tiap client dikonfigurasi melalui script shell idempotent di `/root/setup-network.sh`:

**Alice (`192.220.1.2/24`, Gateway: `192.220.1.1` - SW1)**
```sh
ip link set eth0 up
ip addr flush dev eth0
ip addr add 192.220.1.2/24 dev eth0
ip route replace default via 192.220.1.1 dev eth0
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

**Mika (`192.220.1.3/24`, Gateway: `192.220.1.1` - SW1)**
```sh
ip link set eth0 up
ip addr flush dev eth0
ip addr add 192.220.1.3/24 dev eth0
ip route replace default via 192.220.1.1 dev eth0
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

**Chisa (`192.220.2.2/24`, Gateway: `192.220.2.1` - SW2)**
```sh
ip link set eth0 up
ip addr flush dev eth0
ip addr add 192.220.2.2/24 dev eth0
ip route replace default via 192.220.2.1 dev eth0
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

**Knights (`192.220.3.2/24`, Gateway: `192.220.3.1` - SW3)**
```sh
ip link set eth0 up
ip addr flush dev eth0
ip addr add 192.220.3.2/24 dev eth0
ip route replace default via 192.220.3.1 dev eth0
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

**Eiri (`192.220.3.3/24`, Gateway: `192.220.3.1` - SW3)**
```sh
ip link set eth0 up
ip addr flush dev eth0
ip addr add 192.220.3.3/24 dev eth0
ip route replace default via 192.220.3.1 dev eth0
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

#### C. Verifikasi Pengujian Antar Subnet

Pengujian ping dilakukan melintasi switch yang berbeda untuk memastikan tabel routing router bekerja:

1. **Uji dari Alice (Subnet 1) ke Chisa (Subnet 2) dan Knights (Subnet 3):**
   ```sh
   ping -c 3 192.220.2.2
   ping -c 3 192.220.3.2
   ```
2. **Uji dari Knights (Subnet 3) ke Alice (Subnet 1):**
   ```sh
   ping -c 3 192.220.1.2
   ```

![](assets/03-ping-antar-client.png)

Semua paket ICMP sukses di-reply dengan status RTT stabil dan 0% packet loss.

---

### 4. Firewall Masquerade & DNS Resolver per Client

Agar client tidak hanya bisa saling berkomunikasi lokal tetapi juga dapat mengakses internet secara mandiri (misalnya untuk mengunduh paket via `apk add`), Router Lain harus melakukan translasi alamat jaringan (Network Address Translation / NAT).

#### A. Konfigurasi NAT (iptables) di Router Lain

Aturan NAT MASQUERADE ditambahkan ke tabel `POSTROUTING`:

```sh
if ! iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null; then
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
fi
```

**Penjelasan Konfigurasi iptables:**
- `-t nat`: Menunjuk ke tabel NAT (Network Address Translation).
- `-A POSTROUTING`: Menambahkan rule ke rantai POSTROUTING (dieksekusi saat paket hendak meninggalkan router).
- `-o eth0`: Rule hanya berlaku untuk lalu lintas keluar menuju interface uplink (`eth0` ke NAT1).
- `-j MASQUERADE`: Mengubah source IP private paket client (`192.220.x.x`) menjadi source IP interface `eth0` router (`192.168.122.2`), sehingga paket dapat diterima kembali dari internet.
- `-C ... || -A ...`: Memastikan rule bersifat idempotent (tidak terduplikasi saat script dijalankan ulang).

#### B. DNS Resolver per Client

Di setiap node client, konfigurasi DNS disetel mengarah ke `8.8.8.8` pada `/etc/resolv.conf`:
```sh
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

#### C. Verifikasi Internet dari Client

Pengujian dilakukan dari client (contoh: Chisa dan Knights):

```sh
# Tes koneksi IP internet
ping -c 3 8.8.8.8

# Tes resolusi domain internet
nslookup google.com

# Tes instalasi paket via apk Alpine
apk update
```

![](assets/04-client-internet.png)

Client berhasil melakukan query DNS ke `8.8.8.8` dan mengunduh paket melalui gateway Router Lain.

---

### 5. Persistensi Konfigurasi Reboot & `cek_status.sh`

Di lingkungan simulasi GNS3, container Docker bersifat stateless secara default bila interface di-reboot. Untuk menjamin seluruh alokasi IP, route, dan firewall tetap bertahan setelah reboot:

#### A. Mekanisme Persistensi GNS3
Setiap node dikonfigurasikan dengan opsi *Custom Start Command* pada pengaturan GNS3 Node:
```sh
sh /root/setup-network.sh && /bin/sh
```
Dengan konfigurasi ini, setiap kali container dijalankan ulang (start/reboot), script inisialisasi jaringan akan langsung dieksekusi secara otomatis sebelum masuk ke shell.

#### B. Script Pemeriksaan `/root/cek_status.sh` di Router Lain
Pada Router Lain, disediakan script diagnosa status jaringan di `/root/cek_status.sh` ([script/cek-status.sh](file:///home/caur/programs/jarkom/modul1/script/cek-status.sh)):

```sh
#!/bin/sh
# /root/cek_status.sh  --  Router (Lain)
set -u

echo "=== cek_status.sh | $(hostname) | $(date '+%Y-%m-%d %H:%M:%S') ==="

echo
echo "--- ip -br a ---"
ip -br a

echo
echo "--- iptables -t nat -L -v -n ---"
iptables -t nat -L -v -n
```

**Verifikasi Eksekusi:**
```sh
chmod +x /root/cek_status.sh
/root/cek_status.sh
```

![](assets/05-cek-status-router.png)

Output menampilkan status 4 interface (`eth0`, `eth1`, `eth2`, `eth3`) dalam kondisi UP dengan IP masing-masing, serta tabel NAT `POSTROUTING` yang memuat rule `MASQUERADE`.

---

### 6. Traffic Generator di Mika & Analisis Wireshark

Pada skenario ini, aktivitas jaringan disimulasikan menggunakan generator traffic pada node **Mika**, dan paket yang lewat dianalisis menggunakan Wireshark.

1. **Persiapan Capture**: Wireshark diaktifkan pada tautan antara node **Mika** dan **Switch 1** (`SW1`).
2. **Eksekusi Traffic Generator**: Script generator dijalankan di node Mika untuk membangkitkan beragam paket request (DNS dan ICMP).
3. **Display Filter Wireshark**:
   - Filter DNS: `dns` — Menampilkan paket query DNS (tipe A/AAAA) serta jawaban respon dari nameserver.
   - Filter ICMP: `icmp` — Menampilkan paket echo request (`Type 8`) dan echo reply (`Type 0`).
   - Filter gabungan: `dns || icmp`

![](assets/06-traffic-dns-icmp.png)

Capture menunjukkan aktivitas pertukaran paket layer transport dan internetwork yang dibangkitkan oleh Mika secara periodik.

---

### 7. FTP Server vsFTPd di Chisa (The Wired)

Pada node **Chisa**, dibangun server FTP menggunakan `vsftpd` untuk melayani transfer berkas di The Wired dengan spesifikasi keamanan ketat:
- **Shared Folder**: `/var/wired/data`
- **Direktori Log**: `/var/wired` (berkas log `vsftpd.log` dan `xferlog.log`)
- **Hak Akses Pengguna**:
  - `alice`: **Read & Write** (dapat mengunggah dan mengunduh berkas).
  - `mika`: **Read-Only** (hanya dapat melihat dan mengunduh; unggah ditolak error `550`).
  - `eiri`: **Blacklist** (ditolak saat login; error `530`).

Konfigurasi diotomasi menggunakan script [script/setup-ftp-chisa.sh](file:///home/caur/programs/jarkom/modul1/script/setup-ftp-chisa.sh) (dipasang di node sebagai `/root/setup-ftp.sh`).

#### A. Konfigurasi `vsftpd.conf` di Chisa
```conf
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
```

#### B. Aturan Hak Akses Pengguna
1. **User Creation & Directory Permissions**:
   ```sh
   mkdir -p /var/wired/data /var/wired/empty /etc/vsftpd/user_conf /etc/pam.d
   addgroup -S wired
   chown root:wired /var/wired /var/wired/data
   chmod 2775 /var/wired/data
   
   adduser -D -H -h /var/wired/data -s /sbin/nologin -G wired alice
   echo "alice:alice123" | chpasswd
   
   adduser -D -H -h /var/wired/data -s /sbin/nologin -G wired mika
   echo "mika:mika123" | chpasswd
   
   adduser -D -H -h /var/wired -s /sbin/nologin -G wired eiri
   echo "eiri:eiri123" | chpasswd
   ```

2. **Read-Only Mika via `user_config_dir`**:
   Pada `/etc/vsftpd/user_conf/mika`:
   ```text
   write_enable=NO
   ```
   Pengaturan ini menimpa `write_enable=YES` global khusus untuk user Mika, sehingga operasi `STOR` dan `DELE` akan ditolak dengan respon `550 Permission denied`.

3. **Blacklist Eiri via `user_list`**:
   Pada `/etc/vsftpd/user_list`:
   ```text
   eiri
   ```
   Dengan `userlist_enable=YES` dan `userlist_deny=YES`, user yang terdaftar di berkas ini akan langsung ditolak saat mencoba login (`530 Permission denied`).

4. **Konfigurasi Autentikasi PAM di Alpine**:
   Pada `/etc/pam.d/vsftpd`:
   ```text
   auth    required pam_unix.so
   account required pam_unix.so
   session required pam_unix.so
   ```

#### C. Bukti Verifikasi Pengujian

Pengujian dilakukan langsung menggunakan klien FTP:

1. **Uji Akun Alice (Read & Write):**
   Alice berhasil login (`230 Login successful`), mengunggah berkas `signal_alice.txt`, dan melihat daftar direktori:
   ```text
   Connected to 192.220.2.2.
   220 (vsFTPd 3.0.5)
   Name (192.220.2.2:root): alice
   331 Please specify the password.
   Password:
   230 Login successful.
   Remote system type is UNIX.
   Using binary mode to transfer files.
   ftp> put /tmp/signal_alice.txt signal_alice.txt
   200 PORT command successful. Consider using PASV.
   150 Ok to send data.
   226 Transfer complete.
   50 bytes sent in 0.0003 seconds (163.9700 kbytes/s)
   ftp> ls
   200 PORT command successful. Consider using PASV.
   150 Here comes the directory listing.
   -rw-r--r--    1 1000     101            50 Sep 15 18:05 signal_alice.txt
   226 Directory send OK.
   ```
   ![](assets/07-vsftpd-alice.png)

2. **Uji Akun Mika (Read-Only):**
   Mika berhasil login (`230 Login successful`), dapat melihat berkas `signal_alice.txt`, namun ketika mencoba mengunggah berkas, server menolak dengan kode `550`:
   ```text
   Connected to 192.220.2.2.
   220 (vsFTPd 3.0.5)
   Name (192.220.2.2:root): mika
   331 Please specify the password.
   Password:
   230 Login successful.
   Remote system type is UNIX.
   Using binary mode to transfer files.
   ftp> ls
   200 PORT command successful. Consider using PASV.
   150 Here comes the directory listing.
   -rw-r--r--    1 1000     101            50 Sep 15 18:05 signal_alice.txt
   226 Directory send OK.
   ftp> put /tmp/signal_alice.txt test_mika.txt
   200 PORT command successful. Consider using PASV.
   550 Permission denied.
   ```
   ![](assets/07-vsftpd-mika.png)

3. **Uji Akun Eiri (Blacklist):**
   Saat user `eiri` mencoba login, vsFTPd langsung menolak autentikasi sesuai daftar `user_list`:
   ```text
   Connected to 192.220.2.2.
   220 (vsFTPd 3.0.5)
   Name (192.220.2.2:root): eiri
   530 Permission denied.
   ftp: Login failed.
   ```
   ![](assets/07-vsftpd-eiri.png)

---

### 8. Praktik FTP Client dari Knights (Upload via Alice)

Klien FTP dijalankan dari node **Knights** (`192.220.3.2`) untuk melakukan transfer data menuju Chisa (`192.220.2.2`) dengan menggunakan akun `alice`.

1. **Paket FTP Client di Knights**: Diinstal via `apk add --no-cache inetutils-ftp`.
2. **Koneksi & Transfer**:
   ```sh
   ftp 192.220.2.2
   # User: alice, Pass: alice123
   ftp> passive
   ftp> put upload_knights.txt upload_knights.txt
   ```
3. **Analisis Wireshark**:
   - Filter: `ftp || ftp-data`
   - Teridentifikasi instruksi kendali `PASV`, respon `227 Entering Passive Mode (192,220,2,2,p1,p2)`.
   - Perhitungan port data pasif: `(p1 * 256) + p2` (berada di rentang port pasif `40000–40100`).
   - Perintah pengiriman `STOR upload_knights.txt`.
   - Konfirmasi transfer selesai dari server: kode status `226 Transfer complete`.

![](assets/08-wireshark-knights-ftp.png)

---

### 9. Download FTP oleh Mika & Bukti Read-Only 550

Pengujian dilakukan dari node **Mika** (`192.220.1.3`) mengunduh berkas "Protokol Tujuh" dari Chisa dan membuktikan penolakan izin tulis:

1. **Download Berkas (RETR)**:
   ```sh
   ftp 192.220.2.2
   # User: mika, Pass: mika123
   ftp> get protokol_tujuh.txt
   ```
   Respon server: `150 Opening BINARY mode data connection` dilanjutkan `226 Transfer complete`.
2. **Uji Penolakan Upload (STOR)**:
   ```sh
   ftp> put berkas_rahasia.txt
   ```
   Respon server: `550 Permission denied`.

![](assets/09-mika-ftp-ro.png)

