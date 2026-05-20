#!/bin/bash

# Build an Omarchy-Void installable ISO using void-mklive.
#
# Usage:
#   ./iso/build.sh [OUTPUT_PATH]
#
# Environment:
#   OMARCHY_MIRROR      - Void mirror URL (default: repo-fastly.voidlinux.org/current)
#   HYPRLAND_REPO       - Hyprland package repo URL (file:// or https://)
#   MKLIVE_DIR          - Path to void-mklive checkout

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMARCHY_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
MIRROR_URL="${OMARCHY_MIRROR:-https://repo-fastly.voidlinux.org/current}"
OUTPUT="${1:-$SCRIPT_DIR/omarchy-void-$(date +%Y%m%d)-x86_64.iso}"
HYPRLAND_REPO="${HYPRLAND_REPO:-}"

MKLIVE_DIR="${MKLIVE_DIR:-$OMARCHY_PATH/../void-mklive}"

if [[ ! -x "$MKLIVE_DIR/mklive.sh" ]]; then
  echo "Error: void-mklive not found at $MKLIVE_DIR"
  echo "Clone it: git clone https://github.com/void-linux/void-mklive $OMARCHY_PATH/../void-mklive"
  exit 1
fi

patch_mklive_efi_boot_dir() {
  local mklive_sh="$MKLIVE_DIR/mklive.sh"

  # xorriso warns when /EFI/BOOT doesn't exist in the ISO filesystem, even though
  # it is present inside /boot/grub/efiboot.img (El Torito). Some Windows USB tools
  # rely on /EFI/BOOT being present as normal files.
  if grep -q "OMARCHY_EFI_BOOT_COPY" "$mklive_sh"; then
    return
  fi

  local tmp
  tmp="$(mktemp)"

  awk '
    /^[[:space:]]*generate_iso_image$/ && !inserted {
      print "";
      print "# OMARCHY_EFI_BOOT_COPY: copy EFI boot files into ISO filesystem for Windows tools";
      print "if [ -e \"$VOIDTARGETDIR/tmp/bootx64.efi\" ]; then";
      print "  mkdir -p \"$IMAGEDIR/EFI/BOOT\"";
      print "  cp -f \"$VOIDTARGETDIR/tmp/bootx64.efi\" \"$IMAGEDIR/EFI/BOOT/BOOTX64.EFI\"";
      print "fi";
      print "if [ -e \"$VOIDTARGETDIR/tmp/bootia32.efi\" ]; then";
      print "  mkdir -p \"$IMAGEDIR/EFI/BOOT\"";
      print "  cp -f \"$VOIDTARGETDIR/tmp/bootia32.efi\" \"$IMAGEDIR/EFI/BOOT/BOOTIA32.EFI\"";
      print "fi";
      print "if [ -e \"$VOIDTARGETDIR/tmp/bootaa64.efi\" ]; then";
      print "  mkdir -p \"$IMAGEDIR/EFI/BOOT\"";
      print "  cp -f \"$VOIDTARGETDIR/tmp/bootaa64.efi\" \"$IMAGEDIR/EFI/BOOT/BOOTAA64.EFI\"";
      print "fi";
      print "";
      inserted=1
    }
    { print }
  ' "$mklive_sh" >"$tmp"

  mv "$tmp" "$mklive_sh"
  chmod +x "$mklive_sh"
}

patch_mklive_efi_boot_dir

# Gather packages for the ISO
ISO_PACKAGES=$(grep -v '^#' "$SCRIPT_DIR/omarchy.packages" | grep -v '^$' | tr '\n' ' ')

echo "Building Omarchy-Void ISO..."
echo "  Output: $OUTPUT"
echo "  Mirror: $MIRROR_URL"
echo "  Packages: $(echo "$ISO_PACKAGES" | wc -w)"

# Build extra -r flags for additional repos
EXTRA_REPOS=()
if [[ -n $HYPRLAND_REPO ]]; then
  EXTRA_REPOS+=(-r "$HYPRLAND_REPO")
fi

# Skip sudo if already running as root (e.g., in containers)
if (( EUID == 0 )); then
  # mklive.sh sources ./lib.sh, so cd into its directory first
  (cd "$MKLIVE_DIR" && ./mklive.sh \
    -a x86_64 \
    ${EXTRA_REPOS[@]+"${EXTRA_REPOS[@]}"} \
    -r "$MIRROR_URL" \
    -p "$ISO_PACKAGES" \
    -I "$SCRIPT_DIR/overlay" \
    -o "$OUTPUT")
else
  (cd "$MKLIVE_DIR" && sudo ./mklive.sh \
    -a x86_64 \
    ${EXTRA_REPOS[@]+"${EXTRA_REPOS[@]}"} \
    -r "$MIRROR_URL" \
    -p "$ISO_PACKAGES" \
    -I "$SCRIPT_DIR/overlay" \
    -o "$OUTPUT")
fi
echo "ISO built: $OUTPUT"
