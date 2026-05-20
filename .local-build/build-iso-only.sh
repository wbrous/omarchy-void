#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO_VERSION="${ISO_VERSION:-local}"

printf '\n=== Local Omarchy-Void ISO-only build started at %s ===\n' "$(date -Is)"

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
xbps-query --repository=/src/.local-build/local-repo -Rs '^hyprland-' || true
cd /src

git clone --depth 1 https://github.com/void-linux/void-mklive /void-mklive
bash iso/build.sh "/src/.local-build/omarchy-void-${ISO_VERSION}-x86_64.iso"
VOID_SCRIPT

printf '\n=== Local Omarchy-Void ISO-only build finished at %s ===\n' "$(date -Is)"
