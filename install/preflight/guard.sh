abort() {
  echo -e "\e[31mOmarchy install requires: $1\e[0m"
  echo
  gum confirm "Proceed anyway on your own accord and without assistance?" || exit 1
}

# Must be Void Linux
if [[ ! -f /etc/void-release ]]; then
  abort "Void Linux"
fi

# Must not be running as root
if (( EUID == 0 )); then
  abort "Running as root (not user)"
fi

# Must be x86 only to fully work
if [[ $(uname -m) != "x86_64" ]]; then
  abort "x86_64 CPU"
fi

# Must have secure boot disabled
if command -v mokutil &>/dev/null && mokutil --sb-state 2>/dev/null | grep -qi "enabled"; then
  abort "Secure Boot disabled"
fi

# Must not have Gnome or KDE already installed
if xbps-query -s gnome-shell &>/dev/null || xbps-query -s plasma-desktop &>/dev/null; then
  abort "Fresh + Vanilla Void"
fi

# Must have btrfs root filesystem
[[ $(findmnt -n -o FSTYPE /) = "btrfs" ]] || abort "Btrfs root filesystem"

# Cleared all guards
echo "Guards: OK"
