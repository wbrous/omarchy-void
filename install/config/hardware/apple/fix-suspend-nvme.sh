# Fix NVMe suspend issues on MacBook models
# This prevents NVMe drives from failing to wake from sleep properly
MACBOOK_MODEL=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)

if [[ $MACBOOK_MODEL =~ MacBook(8,1|9,1|10,1)|MacBookPro13,[123]|MacBookPro14,[123] ]]; then
  echo "Detected MacBook model: $MACBOOK_MODEL"

  NVME_DEVICE="/sys/bus/pci/devices/0000:01:00.0/d3cold_allowed"

  if [[ -f $NVME_DEVICE ]]; then
    echo "Applying NVMe suspend fix..."

    # Create runit service for the NVMe suspend fix
    SVC_DIR="/etc/sv/omarchy-nvme-suspend-fix"
    sudo mkdir -p "$SVC_DIR"
    cat <<'EOF' | sudo tee "$SVC_DIR/run" >/dev/null
#!/bin/sh
exec 1>&2
echo 0 > /sys/bus/pci/devices/0000:01:00.0/d3cold_allowed
exec pause
EOF
    sudo chmod +x "$SVC_DIR/run"

    chrootable_runit_enable omarchy-nvme-suspend-fix
  else
    echo "Warning: NVMe device not found at expected PCI address (0000:01:00.0)"
    echo "This fix may not be needed for this MacBook model"
  fi
fi
