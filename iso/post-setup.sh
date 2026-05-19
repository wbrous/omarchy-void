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

# Configure GRUB for os-prober (dual-boot support)
if [[ -f /etc/default/grub ]]; then
  if ! grep -q "GRUB_DISABLE_OS_PROBER" /etc/default/grub; then
    echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
  fi
fi

# Configure Plymouth default theme
if command -v plymouth-set-default-theme &>/dev/null; then
  plymouth-set-default-theme omarchy 2>/dev/null || true
fi

# Ensure omarchy user exists for live environment
if ! id -u omarchy &>/dev/null; then
  useradd -m -G wheel,audio,video,input,netdev,storage -s /bin/bash omarchy
  echo "omarchy:omarchy" | chpasswd
fi

# Enable sudo for wheel group
if [[ -f /etc/sudoers ]]; then
  if ! grep -q "^%wheel ALL=(ALL:ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers
  fi
fi

# Generate initramfs with dracut
dracut --force --regenerate-all

# Configure xbps to use Makrennel hyprland-void repo
cat > /etc/xbps.d/20-hyprland-void.conf <<'EOF'
repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc
EOF

# Update xbps repository indexes
xbps-install -S

echo "Omarchy live environment configured."
