#!/bin/bash
# Post-setup script run inside the void-mklive chroot after packages are installed.
# Configures the live environment for Omarchy.

set -euo pipefail

# Enable required runit services
for svc in dbus elogind seatd polkitd sddm NetworkManager iwd bluetoothd; do
  if [[ -d /etc/sv/$svc ]]; then
    ln -sf /etc/sv/$svc /var/service/
  fi
done

# Enable os-prober for Windows dual-boot detection
if [[ -f /etc/default/grub ]] && ! grep -q "GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
  echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
fi

# Set Plymouth default theme
if command -v plymouth-set-default-theme &>/dev/null; then
  plymouth-set-default-theme omarchy 2>/dev/null || true
fi

# Create live user
if ! id -u omarchy &>/dev/null; then
  useradd -m -G wheel,audio,video,input,netdev,storage -s /bin/bash omarchy
  echo "omarchy:omarchy" | chpasswd
fi

# Enable passwordless sudo for wheel group
if ! grep -q "^%wheel ALL=(ALL:ALL) NOPASSWD: ALL" /etc/sudoers; then
  echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Generate initramfs
dracut --force --regenerate-all

# Sync package indexes (repos already configured via overlay)
xbps-install -S

echo "Omarchy live environment configured."
