# Add elephant to autostart
if ! grep -q 'elephant' ~/.config/hypr/autostart.lua; then
  echo 'o.launch_on_start("elephant")' >> ~/.config/hypr/autostart.lua
fi
