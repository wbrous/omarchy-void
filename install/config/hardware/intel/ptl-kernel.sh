# Install Panther Lake kernel for Dell XPS Panther Lake systems
# The linux-ptl kernel includes audio driver patches not yet in mainline.

if omarchy-hw-match "XPS" && omarchy-hw-intel-ptl; then
  echo "Detected Dell XPS Panther Lake, installing PTL kernel..."

  omarchy-pkg-add linux-ptl linux-ptl-headers
  for pkg in linux linux-headers; do
    sudo xbps-remove -F "$pkg" 2>/dev/null || true
  done

  # Void Linux uses GRUB by default; no limine-entry-tool.
  # If limine is installed, this would need limine-specific config.
  # Omitting limine-entry-tool.d for Void.
fi
