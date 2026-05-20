#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/.local-build"
LOCAL_REPO="$OUTPUT_DIR/local-repo"
ISO_VERSION="${ISO_VERSION:-local}"
ISO_OUTPUT="$OUTPUT_DIR/omarchy-void-${ISO_VERSION}-x86_64.iso"

mkdir -p "$LOCAL_REPO"

printf '\n=== Local Omarchy-Void ISO build started at %s ===\n' "$(date -Is)"
printf 'Root: %s\n' "$ROOT_DIR"
printf 'Local repo: %s\n' "$LOCAL_REPO"
printf 'ISO output: %s\n\n' "$ISO_OUTPUT"

printf '\n=== Building Hyprland packages ===\n'
docker run --privileged --rm -i --userns=host \
  -v "$ROOT_DIR:/src:rw" \
  ghcr.io/void-linux/void-glibc:latest \
  /bin/sh -s <<'VOID_SCRIPT'
set -eu

xbps-install -y -Su xbps
xbps-install -y -Su
xbps-install -y git bash sudo tar gzip xz \
  base-devel cmake meson ninja pkg-config \
  util-linux shadow

useradd -m -s /bin/bash -G xbuilder builder

git clone --depth 1 https://github.com/void-linux/void-packages.git /void-packages

echo XBPS_CHROOT_CMD=uchroot >> /void-packages/etc/conf

for dir in /src/hyprland-void/srcpkgs/*/; do
  pkg=$(basename "$dir")
  if [ -L "${dir%/}" ]; then
    cp -a "${dir%/}" "/void-packages/srcpkgs/$pkg"
    continue
  fi
  if [ -d "/void-packages/srcpkgs/$pkg" ] || [ "$pkg" = "sdbus-cpp" ]; then
    echo "Skipping $pkg (using Void's version instead)"
    continue
  fi
  cp -r "$dir" "/void-packages/srcpkgs/$pkg"
done

if [ -d /src/ci/srcpkgs-overrides ]; then
  cp -r /src/ci/srcpkgs-overrides/* /void-packages/srcpkgs/
fi

sed -E -i 's/\btomlplusplus\b(-devel)?/tomlplusplus-devel/g' /void-packages/srcpkgs/*/template
sed -E -i 's/\bsdbus-cpp\b(-devel)?/sdbus-c++-devel/g' /void-packages/srcpkgs/*/template

while read -r line; do
  pkgname=$(echo "$line" | awk '{print $2}' | sed 's/-[0-9].*//')
  if [ -n "$pkgname" ] && [ -d "/void-packages/srcpkgs/$pkgname" ] && [ -d "/src/hyprland-void/srcpkgs/$pkgname" ]; then
    echo "$line" >> /void-packages/common/shlibs
  fi
done < /src/hyprland-void/common/shlibs

chown -R builder:builder /void-packages
mkdir -p /src/.local-build/local-repo
chown builder:builder /src/.local-build/local-repo

su -s /bin/bash builder -c "
  set -x
  id
  cd /void-packages
  cat etc/conf
  ls -l /usr/bin/xbps-uchroot
  ./xbps-src binary-bootstrap

  for pkg in \
    libspng \
    hyprland-protocols glaze \
    hyprlang hyprgraphics hyprcursor \
    aquamarine hyprland \
    hypridle hyprlock hyprpaper \
    hyprpolkitagent hyprsunset hyprsysteminfo \
    hyprland-qt-support hyprland-qtutils \
    xdg-desktop-portal-hyprland; do
    if [ -d srcpkgs/\$pkg ]; then
      echo \"=== Building \$pkg ===\"
      ./xbps-src -j\$(nproc) pkg \$pkg || {
        echo \"ERROR: \$pkg build failed\"
        exit 1
      }
    fi
  done

  for pattern in aquamarine glaze hypr libspng xdg-desktop-portal-hyprland; do
    cp hostdir/binpkgs/\${pattern}*.xbps /src/.local-build/local-repo/ 2>/dev/null || true
  done
  cd /src/.local-build/local-repo
  xbps-rindex -a *.xbps
  echo \"=== Local repo: \$(ls -1 *.xbps | wc -l) packages ===\"
"
VOID_SCRIPT

printf '\n=== Building ISO ===\n'
docker run --privileged --rm -i \
  -v /dev:/dev \
  -v /lib/modules:/lib/modules:ro \
  -v "$ROOT_DIR:/src:rw" \
  -e ISO_VERSION="$ISO_VERSION" \
  -e MKLIVE_DIR=/void-mklive \
  -e OMARCHY_MIRROR="https://repo-fastly.voidlinux.org/current" \
  -e HYPRLAND_REPO="/src/.local-build/local-repo" \
  ghcr.io/void-linux/void-glibc:latest \
  /bin/sh -s <<'VOID_SCRIPT'
set -eu

xbps-install -y -Su xbps
xbps-install -y -Su
xbps-install -y git bash sudo tar gzip xz \
  findutils util-linux kmod dosfstools e2fsprogs \
  squashfs-tools liblz4 xorriso syslinux

cd /src/.local-build/local-repo
xbps-rindex -a *.xbps 2>/dev/null || true
cd /src

git clone --depth 1 https://github.com/void-linux/void-mklive /void-mklive
bash iso/build.sh "/src/.local-build/omarchy-void-${ISO_VERSION}-x86_64.iso"
VOID_SCRIPT

printf '\n=== Local Omarchy-Void ISO build finished at %s ===\n' "$(date -Is)"
printf 'ISO output: %s\n' "$ISO_OUTPUT"
