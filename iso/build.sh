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
    -r "$MIRROR_URL" \
    ${EXTRA_REPOS[@]+"${EXTRA_REPOS[@]}"} \
    -p "$ISO_PACKAGES" \
    -I "$SCRIPT_DIR/overlay" \
    -o "$OUTPUT")
else
  (cd "$MKLIVE_DIR" && sudo ./mklive.sh \
    -a x86_64 \
    -r "$MIRROR_URL" \
    ${EXTRA_REPOS[@]+"${EXTRA_REPOS[@]}"} \
    -p "$ISO_PACKAGES" \
    -I "$SCRIPT_DIR/overlay" \
    -o "$OUTPUT")
fi
echo "ISO built: $OUTPUT"
