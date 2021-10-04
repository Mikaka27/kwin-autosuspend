#!/bin/bash

systemctl --user disable --now kwin-autosuspend.service
rm -f ~/.config/systemd/user/kwin-autosuspend.service
rm -f ~/.local/bin/kwin-autosuspend.sh