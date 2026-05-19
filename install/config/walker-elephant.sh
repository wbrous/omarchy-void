#!/bin/bash

# Ensure Walker service is started automatically on boot
mkdir -p ~/.config/autostart/
cp $OMARCHY_PATH/default/walker/walker.desktop ~/.config/autostart/

# Void Linux does not use systemd user services; omit restart drop-in.
# Walker will be started via autostart desktop entry.

# Void Linux does not use pacman hooks.
# Omit walker-restart hook; manual restart after updates if needed.

# Link the visual theme menu config
mkdir -p ~/.config/elephant/menus
ln -snf $OMARCHY_PATH/default/elephant/omarchy_themes.lua ~/.config/elephant/menus/omarchy_themes.lua
ln -snf $OMARCHY_PATH/default/elephant/omarchy_background_selector.lua ~/.config/elephant/menus/omarchy_background_selector.lua
ln -snf $OMARCHY_PATH/default/elephant/omarchy_unlocks.lua ~/.config/elephant/menus/omarchy_unlocks.lua
