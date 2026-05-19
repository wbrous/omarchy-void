sudo ln -sf /etc/sv/cupsd /var/service/

# Disable multicast dns in resolved. Avahi will provide this for better network printer discovery
# Void Linux does not use systemd-resolved; no drop-in needed.

sudo ln -sf /etc/sv/avahi-daemon /var/service/

# Enable mDNS resolution for .local domains
sudo sed -i 's/^hosts:.*/hosts: mymachines mdns_minimal [NOTFOUND=return] files myhostname dns/' /etc/nsswitch.conf

# Enable automatically adding remote printers
if ! grep -q '^CreateRemotePrinters Yes' /etc/cups/cups-browsed.conf; then
  echo 'CreateRemotePrinters Yes' | sudo tee -a /etc/cups/cups-browsed.conf
fi

# Void Linux does not package cups-browsed as a separate service in all cases.
# If cups-browsed exists as a runit service, enable it:
if [[ -d /etc/sv/cups-browsed ]]; then
  sudo ln -sf /etc/sv/cups-browsed /var/service/
fi
