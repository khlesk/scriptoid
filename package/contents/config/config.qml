import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "settings-configure"
        source: "config/ConfigGeneral.qml"
    }

    ConfigCategory {
        name: i18n("Tooltip")
        icon: "dialog-information"
        source: "config/ConfigTooltip.qml"
    }

}
