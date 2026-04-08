import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: formLayout

    property string title
    property alias cfg_command: commandField.text
    property string cfg_commandDefault
    property alias cfg_intervalSeconds: intervalField.value
    property int cfg_intervalSecondsDefault: 60
    property alias cfg_fillWidth: fillWidthCheck.checked
    property bool cfg_fillWidthDefault: true
    property alias cfg_padding: paddingField.value
    property int cfg_paddingDefault: 8
    property alias cfg_useCustomFontSize: customFontSizeCheck.checked
    property bool cfg_useCustomFontSizeDefault: false
    property alias cfg_fontSize: fontSizeField.value
    property int cfg_fontSizeDefault: 12
    property alias cfg_useCustomFontFamily: customFontFamilyCheck.checked
    property bool cfg_useCustomFontFamilyDefault: false
    property alias cfg_fontFamily: fontFamilyField.text
    property string cfg_fontFamilyDefault
    property alias cfg_useCustomColor: customColorCheck.checked
    property bool cfg_useCustomColorDefault: false
    property alias cfg_customColor: customColorField.text
    property string cfg_customColorDefault
    property alias cfg_useMonospaceFont: useMonospaceFontCheck.checked
    property bool cfg_useMonospaceFontDefault: false
    property string cfg_textAlignment: "center"
    property string cfg_textAlignmentDefault: "center"
    readonly property int fieldIndent: Kirigami.Units.smallSpacing
    readonly property url homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)

    function textOrEmpty(value) {
        return value === undefined || value === null ? "" : String(value);
    }

    function shellSingleQuote(value) {
        return "'" + textOrEmpty(value).replace(/'/g, "'\"'\"'") + "'";
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

    function alignmentIndex(value) {
        if (value === "left")
            return 0;

        if (value === "right")
            return 2;

        return 1;
    }

    function alignmentValue(index) {
        if (index === 0)
            return "left";

        if (index === 2)
            return "right";

        return "center";
    }

    onCfg_textAlignmentChanged: alignmentField.currentIndex = alignmentIndex(cfg_textAlignment)

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
        Kirigami.FormData.label: i18n("Command:")
        Layout.fillWidth: true
        spacing: formLayout.fieldIndent

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.TextField {
            id: commandField

            Layout.fillWidth: true
            placeholderText: i18n("bash -lc '/path/to/script.sh'")
        }

        QQC2.Button {
            icon.name: "document-edit"
            text: i18n("Edit")
            enabled: formLayout.canEditPath(commandField.text)
            onClicked: formLayout.openConfiguredFile(commandField.text)
            QQC2.ToolTip.visible: hovered
            QQC2.ToolTip.text: enabled ? i18n("Open the configured script in the default text editor") : i18n("Set the command to a file path like /path/to/script.sh or ~/script.sh to enable editing")
        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

    }

    RowLayout {
        Kirigami.FormData.label: i18n("Refresh (s):")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.SpinBox {
            id: intervalField

            from: 1
            to: 86400
            editable: true
        }

    }

    RowLayout {
        Kirigami.FormData.label: i18n("Width mode:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: fillWidthCheck

            text: i18n("Fill available panel space")
        }

    }

    RowLayout {
        Kirigami.FormData.label: i18n("Padding:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.SpinBox {
            id: paddingField

            from: 0
            to: 128
            editable: true
        }

    }

    RowLayout {
        Kirigami.FormData.label: i18n("Font size:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: customFontSizeCheck

            text: i18n("Override font size")
        }

    }

    RowLayout {
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.SpinBox {
            id: fontSizeField

            from: 6
            to: 96
            editable: true
            enabled: customFontSizeCheck.checked
        }

    }

    RowLayout {
        Kirigami.FormData.label: i18n("Font family:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: useMonospaceFontCheck

            text: i18n("Use fixed-width font")
        }

    }

    RowLayout {
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: customFontFamilyCheck

            text: i18n("Override font family")
        }

    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.TextField {
            id: fontFamilyField

            Layout.fillWidth: true
            enabled: customFontFamilyCheck.checked
            placeholderText: i18n("Hack")
        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

    }

    RowLayout {
        Kirigami.FormData.label: i18n("Text color:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: customColorCheck

            text: i18n("Override theme text color")
        }

    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.TextField {
            id: customColorField

            Layout.fillWidth: true
            enabled: customColorCheck.checked
            placeholderText: "#eff0f1"

            validator: RegularExpressionValidator {
                regularExpression: /^(#[0-9a-fA-F]{6}|#[0-9a-fA-F]{8}|[A-Za-z]+)$/
            }

        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

    }

    RowLayout {
        Kirigami.FormData.label: i18n("Text align:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.ComboBox {
            id: alignmentField

            textRole: "text"
            model: [{
                "text": i18n("Left"),
                "value": "left"
            }, {
                "text": i18n("Center"),
                "value": "center"
            }, {
                "text": i18n("Right"),
                "value": "right"
            }]
            currentIndex: alignmentIndex(cfg_textAlignment)
            onCurrentIndexChanged: cfg_textAlignment = alignmentValue(currentIndex)
        }

    }

}
