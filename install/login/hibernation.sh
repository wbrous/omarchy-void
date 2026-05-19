# Run before grub-snapper.sh so the resume hook + cmdline drop-ins are in
# place when dracut regenerates the initramfs. The --no-rebuild flag tells
# the script to skip its own rebuild — grub-snapper will run dracut for us.
omarchy-hibernation-setup --force --no-rebuild
