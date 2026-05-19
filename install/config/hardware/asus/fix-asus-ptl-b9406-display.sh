# Display fix for ASUS ExpertBook B9406 (Panther Lake / Xe3 iGPU).
#
# Panel Replay is Xe3-new, default-on in the xe driver, and has a broken
# exit/wake path on this eDP panel: the panel latches the last-presented
# frame in self-refresh and never wakes for subsequent atomic commits, so
# the screen only updates on a full modeset (e.g. a VT switch). The older
# xe.enable_psr=0 knob does not cover Panel Replay.

if omarchy-hw-asus-expertbook-b9406; then
  # GRUB kernel parameter approach (Void uses GRUB, not limine)
  if ! grep -q "xe.enable_panel_replay=0" /etc/default/grub 2>/dev/null; then
    sudo sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"|GRUB_CMDLINE_LINUX_DEFAULT="\1 xe.enable_panel_replay=0"|' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg
  fi
fi
