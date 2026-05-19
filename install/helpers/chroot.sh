# Starting the installer with OMARCHY_CHROOT_INSTALL=1 will put it into chroot mode
chrootable_runit_enable() {
  local svc="$1"
  if [[ -n ${OMARCHY_CHROOT_INSTALL:-} ]]; then
    ln -sf "/etc/sv/$svc" "$CHROOT/var/service/"
  else
    sudo ln -sf "/etc/sv/$svc" /var/service/
  fi
}

# Export the function so it's available in subshells
export -f chrootable_runit_enable
