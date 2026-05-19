if omarchy-battery-present; then
  powerprofilesctl set balanced || true

  # Enable battery monitoring background loop for low battery notifications
  # Void Linux has no systemd user timers; use a simple background loop script.
  mkdir -p ~/.config/autostart
  cat > ~/.config/autostart/omarchy-battery-monitor.desktop <<'EOF'
[Desktop Entry]
Name=Omarchy Battery Monitor
Exec=/bin/sh -c 'while sleep 30; do $HOME/.local/share/omarchy/bin/omarchy-battery-monitor; done'
Type=Application
Terminal=false
EOF
else
  powerprofilesctl set performance || true
fi
