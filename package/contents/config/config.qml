import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Visuals/Performance")
        icon: "preferences-desktop-theme-global"
        source: "config/ConfigVisuals.qml"
    }
}
