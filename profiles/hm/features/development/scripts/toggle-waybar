#!/usr/bin/env bash
set -eEuo pipefail
shopt -s failglob

if systemctl --user --quiet is-active waybar.service; then
  systemctl --user stop waybar.service
else
  systemctl --user start waybar.service
fi
