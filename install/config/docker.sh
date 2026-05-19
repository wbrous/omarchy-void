# Configure Docker daemon:
# - limit log size to avoid running out of disk
# - use host's DNS resolver
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'EOF'
{
    "log-driver": "json-file",
    "log-opts": { "max-size": "10m", "max-file": "5" },
    "dns": ["172.17.0.1"],
    "bip": "172.17.0.1/16"
}
EOF

# Void Linux does not use systemd-resolved.
# Configure Docker to use a local DNS forwarder or host resolv.conf.
# (No systemd-resolved stub to expose.)

# NOTE: runit has no socket activation. Enable the docker service directly instead.
# sudo ln -sf /etc/sv/docker /var/service/

# Give this user privileged Docker access
sudo usermod -aG docker ${USER}

# Prevent Docker from blocking boot on network-online.target
# On runit this is not a concern; services start in parallel.

