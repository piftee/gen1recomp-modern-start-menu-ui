#!/bin/sh
set -eu

root=${POKEPORT_ICON_ROOT:-$(pwd)}
POKEPORT_ICON_ROOT="$root" love "$root/tools/start_menu_icon_nikoichu"
