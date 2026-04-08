import "../../code/Localization.js" as Localization
import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: formLayout

    readonly property string localeName: Qt.locale().name || "en_US"
    property string title
    property alias cfg_tooltipEnabled: tooltipEnabledCheck.checked
    property bool cfg_tooltipEnabledDefault: false
    property alias cfg_tooltipCommand: tooltipCommandField.text
    property string cfg_tooltipCommandDefault
    property alias cfg_tooltipIntervalSeconds: tooltipIntervalField.value
    property int cfg_tooltipIntervalSecondsDefault: 60
    property alias cfg_tooltipDefaultText: tooltipDefaultTextField.text
    property string cfg_tooltipDefaultTextDefault: l10n("Scriptoid")
    readonly property int fieldIndent: Kirigami.Units.smallSpacing
    readonly property url homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)

    function l10n(key) {
        return Localization.translate(localeName, key, i18n(key));
    }

    function textOrEmpty(value) {
        return value === undefined || value === null ? "" : String(value);
    }

    function localPathFromUrl(value) {
        var path = textOrEmpty(value);
        if (path.indexOf("file://") === 0)
            path = decodeURIComponent(path.slice("file://".length));

        return path;
    }

    function normalizeEditablePath(path) {
        var normalized = textOrEmpty(path).trim();
        if (!normalized.length)
            return "";

        if (normalized.indexOf("file://") === 0)
            normalized = decodeURIComponent(normalized.slice("file://".length));

        if (normalized === "/" || normalized === "~" || normalized === "~/")
            return "";

        if (normalized.indexOf("~/") === 0)
            normalized = localPathFromUrl(homeUrl) + normalized.slice(1);

        if (normalized.charAt(0) !== "/")
            return "";

        if (normalized.indexOf("//") !== -1)
            return "";

        if (normalized.charAt(normalized.length - 1) === "/")
            return "";

        return normalized;
    }

    function canEditPath(commandText) {
        return normalizeEditablePath(commandText).length > 0;
    }

    function openConfiguredFile(commandText) {
        var path = normalizeEditablePath(commandText);
        if (!path.length)
            return ;

        Qt.openUrlExternally("file://" + encodeURI(path));
    }

    Binding {
        target: formLayout
        property: "implicitWidth"
        value: formLayout.width
        when: formLayout.width > 0
        restoreMode: Binding.RestoreBinding
    }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: ""
    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Tooltip:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: tooltipEnabledCheck

            text: formLayout.l10n("Run command for tooltip text")
        }

    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Command:")
        Layout.fillWidth: true
        spacing: formLayout.fieldIndent

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.TextField {
            id: tooltipCommandField

            Layout.fillWidth: true
            enabled: formLayout.cfg_tooltipEnabled
            placeholderText: formLayout.l10n("bash -lc '/path/to/script.sh'")
        }

        QQC2.Button {
            icon.name: "document-edit"
            text: formLayout.l10n("Edit")
            enabled: formLayout.cfg_tooltipEnabled && formLayout.canEditPath(tooltipCommandField.text)
            onClicked: formLayout.openConfiguredFile(tooltipCommandField.text)
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: enabled ? formLayout.l10n("Open the configured script in the default text editor") : formLayout.l10n("Set the command to a file path like /path/to/script.sh or ~/script.sh to enable editing")
        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Refresh (s):")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.SpinBox {
            id: tooltipIntervalField

            from: 1
            to: 86400
            editable: true
            enabled: formLayout.cfg_tooltipEnabled
        }

    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Default text:")
        Layout.fillWidth: true
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.TextField {
            id: tooltipDefaultTextField

            Layout.fillWidth: true
            placeholderText: formLayout.l10n("Scriptoid")
        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

    }

}
