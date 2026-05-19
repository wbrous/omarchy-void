# Raise soft file descriptor limit from the default of 1024 to 1048576
# so dev tools (VS Code:, Docker, dev servers, databases) get the headroom they need
sudo install -d /etc/security/limits.d

sudo tee /etc/security/limits.d/omarchy.conf >/dev/null <<'EOF'
* soft nofile 1048576
* hard nofile 1048576
EOF
