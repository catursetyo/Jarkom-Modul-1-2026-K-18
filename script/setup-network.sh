mkdir -p /root
cat > /root/setup-network.sh << 'EOF'
#!/bin/bash

# eth0 -> ke NAT1 (static, sesuai default GNS3 NAT1)
ip link set eth0 up
ip addr add 192.168.122.2/24 dev eth0
ip route add default via 192.168.122.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# eth1 -> ke Switch1 (Alice & Mika)
ip link set eth1 up
ip addr add 192.220.1.1/24 dev eth1

# eth2 -> ke Switch2 (Chisa)
ip link set eth2 up
ip addr add 192.220.2.1/24 dev eth2

# eth3 -> ke Switch3 (Knights & Eiri)
ip link set eth3 up
ip addr add 192.220.3.1/24 dev eth3

# Aktifkan IP forwarding (routing antar subnet)
echo 1 > /proc/sys/net/ipv4/ip_forward

# NAT/masquerade supaya client di subnet bisa akses internet lewat eth0
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
EOF

chmod +x /root/setup-network.sh
