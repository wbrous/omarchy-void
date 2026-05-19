# Void Linux does not use systemd-resolved.
# Use openresolv to manage /etc/resolv.conf dynamically.
# Ensure openresolv is installed and configured.

if command -v resolvconf >/dev/null 2>&1; then
  echo "openresolv is available; /etc/resolv.conf will be managed by resolvconf."
else
  echo "Consider installing openresolv for dynamic DNS management."
fi

# Remove any stale systemd-resolved symlink if present
if [[ -L /etc/resolv.conf && $(readlink /etc/resolv.conf) == *systemd* ]]; then
  sudo rm -f /etc/resolv.conf
  echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf >/dev/null
fi
