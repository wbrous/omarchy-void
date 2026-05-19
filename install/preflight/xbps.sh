if [[ -n ${OMARCHY_ONLINE_INSTALL:-} ]]; then
  # Configure Void repositories
  sudo mkdir -p /etc/xbps.d

  # Main repos
  sudo cp -f ~/.local/share/omarchy/default/xbps/repositories-${OMARCHY_MIRROR:-stable}.conf /etc/xbps.d/10-omarchy-repositories.conf

  # Sync and update
  sudo xbps-install -Su

  # Install key base packages
  omarchy-pkg-add base-system
fi
