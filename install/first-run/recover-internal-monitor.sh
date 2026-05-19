# Add monitor recovery to Hyprland autostart (Void Linux uses runit, no systemd --user)
autostart_file="$HOME/.config/hypr/autostart.lua"
if [[ -f $autostart_file ]] && ! grep -q "omarchy-recover-internal-monitor" "$autostart_file" 2>/dev/null; then
  echo 'o.launch_on_start("omarchy-recover-internal-monitor")' >> "$autostart_file"
fi
