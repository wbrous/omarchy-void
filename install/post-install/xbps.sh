# Configure final xbps repo state
sudo cp -f ~/.local/share/omarchy/default/xbps/repositories-${OMARCHY_MIRROR:-stable}.conf /etc/xbps.d/10-omarchy-repositories.conf

# Remove any stale repository caches
sudo rm -f /var/cache/xbps/*

# Sync to final state
sudo xbps-install -Su
