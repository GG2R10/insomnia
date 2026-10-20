#!/usr/bin/env bash
#
# Local dev deploy: installs/upgrades ./package into ~/.local/share/plasma/plasmoids
# with kpackagetool6 (no zip + "Install from file" in the UI).
#
# usage: ./dev.sh            install or upgrade
#        ./dev.sh -r         ...and restart plasmashell so QML changes load
#        ./dev.sh -v         ...and open it in plasmoidviewer (if installed)
#        ./dev.sh -u         uninstall
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
PKG=package
ID="$(python3 -c 'import json;print(json.load(open("package/metadata.json"))["KPlugin"]["Id"])')"

restart=0; view=0; remove=0
for a in "$@"; do
    case "$a" in
        -r) restart=1 ;;
        -v) view=1 ;;
        -u) remove=1 ;;
        *) echo "usage: $0 [-r] [-v] [-u]" >&2; exit 1 ;;
    esac
done

chmod +x "$PKG"/contents/code/*.sh

if [ "$remove" = 1 ]; then
    kpackagetool6 --type Plasma/Applet --remove "$ID"
    exit 0
fi

if kpackagetool6 --type Plasma/Applet --list 2>/dev/null | grep -qF "$ID"; then
    kpackagetool6 --type Plasma/Applet --upgrade "$PKG"
else
    kpackagetool6 --type Plasma/Applet --install "$PKG"
fi

if [ "$restart" = 1 ]; then
    systemctl --user restart plasma-plasmashell.service
fi

if [ "$view" = 1 ]; then
    exec plasmoidviewer -a "$ID"
fi
