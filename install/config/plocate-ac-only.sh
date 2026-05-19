# Run plocate-updatedb only when on AC power.
# On Void Linux we use a cron job that checks AC status instead of a systemd drop-in.
sudo install -d /etc/cron.d

sudo tee /etc/cron.d/plocate >/dev/null <<'EOF'
# Run plocate updatedb every 24 hours, but skip if on battery
0 3 * * * root /bin/sh -c 'for ps in /sys/class/power_supply/*; do [ -r "$ps/online" ] || continue; [ "$(cat "$ps/online")" = "0" ] && exit 0; done; /usr/bin/updatedb'
EOF
