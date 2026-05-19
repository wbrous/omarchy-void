# Install GRUB, os-prober, and snapper support
omarchy-pkg-add grub grub-btrfs os-prober snapper

# Enable os-prober in GRUB config
if ! grep -q "GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
  echo "Enabling os-prober in GRUB..."
  echo 'GRUB_DISABLE_OS_PROBER=false' | sudo tee -a /etc/default/grub >/dev/null
fi

# Detect boot mode
[[ -d /sys/firmware/efi ]] && EFI=true

# Install GRUB to ESP or MBR as appropriate
if [[ -n $EFI ]]; then
  # Find the EFI system partition
  ESP=$(findmnt -n -o SOURCE /boot/efi 2>/dev/null || findmnt -n -o SOURCE /boot 2>/dev/null)
  if [[ -n $ESP ]]; then
    sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=omarchy --removable
  else
    echo "Warning: Could not find EFI system partition" >&2
    sudo grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=omarchy --removable
  fi
else
  # BIOS boot - install to the disk containing /
  ROOT_DISK=$(findmnt -n -o SOURCE / | sed 's/\[.*\]//;s/[0-9]*$//')
  sudo grub-install --target=i386-pc "$ROOT_DISK"
fi

# Only snapshot root — /home is user data; rolling it back loses user work
if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
  sudo snapper -c root create-config /
fi
sudo cp "$OMARCHY_PATH/default/snapper/root" /etc/snapper/configs/root

# Disable btrfs quotas — full qgroup accounting is a major performance drag
sudo btrfs quota disable / 2>/dev/null || true

# Enable snapper cleanup service (Void uses runit, but snapper may have a systemd unit for cleanup timers)
# On Void, we rely on cron or manual cleanup; skip chrootable_systemctl_enable for snapper

# Regenerate initramfs and GRUB config
echo "Regenerating initramfs..."
sudo dracut --force --regenerate-all

echo "Regenerating GRUB config..."
sudo grub-mkconfig -o /boot/grub/grub.cfg
