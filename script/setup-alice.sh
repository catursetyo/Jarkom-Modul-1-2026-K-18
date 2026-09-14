mkdir -p /root
cat > /root/setup-network.sh << 'EOF'
#!/bin/bash
ip link set eth0 up
ip addr add 192.220.1.2/24 dev eth0
ip route add default via 192.220.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf
EOF
chmod +x /root/setup-network.sh
/root/setup-network.sh
