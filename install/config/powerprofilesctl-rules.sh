if omarchy-battery-present; then
  cat <<EOF | sudo tee "/etc/udev/rules.d/99-power-profile.rules"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/nohup $HOME/.local/share/omarchy/bin/omarchy-powerprofiles-set >/dev/null 2>&1 &"
SUBSYSTEM=="power_supply", ATTR{type}=="USB", RUN+="/usr/bin/nohup $HOME/.local/share/omarchy/bin/omarchy-powerprofiles-set >/dev/null 2>&1 &"
EOF

  sudo ln -sf /etc/sv/power-profiles-daemon /var/service/ 2>/dev/null || true

  sudo udevadm control --reload 2>/dev/null
  sudo udevadm trigger --subsystem-match=power_supply 2>/dev/null
fi
