#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/.config/wallpapers"
files=("$WALLPAPER_DIR"/**/*.*)
random_file="${files[RANDOM % ${#files[@]}]}"
awww img "$random_file"
