import "../code/Localization.js" as Localization
import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    readonly property string localeName: Qt.locale().name || "en_US"

    function l10n(key) {
        return Localization.translate(localeName, key, i18n(key));
    }

    ConfigCategory {
        name: l10n("General")
        icon: "settings-configure"
        source: "config/ConfigGeneral.qml"
    }

    ConfigCategory {
        name: l10n("Tooltip")
        icon: "dialog-information"
        source: "config/ConfigTooltip.qml"
    }

}
