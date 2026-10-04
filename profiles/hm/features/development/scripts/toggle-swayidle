#!/usr/bin/env bash
set -eEuo pipefail
shopt -s failglob

if systemctl --user --quiet is-active swayidle.service; then
  systemctl --user --quiet stop swayidle.service
else
  systemctl --user --quiet start swayidle.service
fi
