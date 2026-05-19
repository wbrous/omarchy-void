# Ensure iwd service will be started
sudo ln -sf /etc/sv/iwd /var/service/

# Void Linux uses dhcpcd by default; no equivalent to systemd-networkd-wait-online.
