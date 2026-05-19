if omarchy-battery-present; then
  cat <<EOF | sudo tee "/etc/udev/rules.d/99-wifi-powersave.rules"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="/usr/bin/nohup $HOME/.local/share/omarchy/bin/omarchy-wifi-powersave on >/dev/null 2>&1 &"
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="/usr/bin/nohup $HOME/.local/share/omarchy/bin/omarchy-wifi-powersave off >/dev/null 2>&1 &"
EOF

  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=power_supply
fi
