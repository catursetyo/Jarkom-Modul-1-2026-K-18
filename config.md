## Router Network Configuration

auto eth0
iface eth0 inet dhcp
	hostname debinet-router

auto eth1
iface eth1 inet static
	address 192.220.1.1
	netmask 255.255.255.0

auto eth2
iface eth2 inet static
	address 192.220.2.1
	netmask 255.255.255.0

auto eth3
iface eth3 inet static
	address 192.220.3.1
	netmask 255.255.255.0
