#!/bin/sh

systemctl --user disable --now kwin-autosuspend.service
cp src/kwin-autosuspend.sh ~/.local/bin/
chmod +x ~/.local/bin/kwin-autosuspend.sh
cp src/kwin-autosuspend.service ~/.config/systemd/user/
systemctl --user enable --now kwin-autosuspend.service