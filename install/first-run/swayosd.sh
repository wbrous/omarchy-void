# Add swayosd-server to autostart
if ! grep -q 'swayosd-server' ~/.config/hypr/autostart.lua; then
  echo 'o.launch_on_start("swayosd-server")' >> ~/.config/hypr/autostart.lua
fi
