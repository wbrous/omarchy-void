# Enable Flexible Return and Event Delivery on Intel Panther Lake.

GRUB_DEFAULT="/etc/default/grub"

if omarchy-hw-intel-ptl; then
  if [[ -f $GRUB_DEFAULT ]] && ! grep -q 'fred=on' "$GRUB_DEFAULT"; then
    sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 fred=on"/' "$GRUB_DEFAULT"
  fi
fi
