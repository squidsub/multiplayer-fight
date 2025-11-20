#!/bin/sh
printf '\033c\033]0;%s\a' MultiplayerFight
base_path="$(dirname "$(realpath "$0")")"
"$base_path/MultiplayerFight.x86_64" "$@"
