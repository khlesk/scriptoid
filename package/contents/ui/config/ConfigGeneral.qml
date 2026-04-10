import "../../code/Localization.js" as Localization
import QtCore
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: formLayout

    readonly property string localeName: Qt.locale().name || "en_US"
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
    property alias cfg_fontFamily: fontFamilyValue.value
    property string cfg_fontFamilyDefault
    property alias cfg_useCustomColor: customColorCheck.checked
    property bool cfg_useCustomColorDefault: false
    property alias cfg_customColor: customColorValue.value
    property string cfg_customColorDefault
    property alias cfg_useMonospaceFont: useMonospaceFontCheck.checked
    property bool cfg_useMonospaceFontDefault: false
    property string cfg_textAlignment: "center"
    property string cfg_textAlignmentDefault: "center"
    property var fontFamilyOptions: []
    property var filteredFontFamilyOptions: []
    property string fontFamilyFilter: ""
    readonly property int fieldIndent: Kirigami.Units.smallSpacing
    readonly property real trailingActionWidth: editButton.implicitWidth
    readonly property url homeUrl: StandardPaths.writableLocation(StandardPaths.HomeLocation)

    function l10n(key) {
        return Localization.translate(localeName, key, i18n(key));
    }

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

    function fontFamilyIndex(value, options) {
        var normalized = textOrEmpty(value).trim();
        var source = options || filteredFontFamilyOptions;
        for (var i = 0; i < source.length; ++i) {
            if (textOrEmpty(source[i].value) === normalized)
                return i;

        }
        return -1;
    }

    function refreshFontFamilyOptions(selectedValue) {
        var normalized = textOrEmpty(selectedValue).trim();
        var fonts = Qt.fontFamilies();
        var options = [];
        var hasSelected = normalized.length === 0;
        var requireMonospace = cfg_useMonospaceFont;
        fonts.sort(function(left, right) {
            return left.localeCompare(right);
        });
        for (var i = 0; i < fonts.length; ++i) {
            var family = textOrEmpty(fonts[i]).trim();
            if (!family.length)
                continue;

            if (requireMonospace && !isMonospaceFamily(family))
                continue;

            if (family === normalized)
                hasSelected = true;

            options.push({
                "text": family,
                "value": family
            });
        }
        if (!hasSelected && normalized.length && (!requireMonospace || isMonospaceFamily(normalized)))
            options.unshift({
            "text": normalized,
            "value": normalized
        });

        fontFamilyOptions = options;
        refreshFilteredFontFamilyOptions();
    }

    function refreshFilteredFontFamilyOptions() {
        var query = textOrEmpty(fontFamilyFilter).trim().toLocaleLowerCase();
        var filtered = [];
        for (var i = 0; i < fontFamilyOptions.length; ++i) {
            var option = fontFamilyOptions[i];
            var family = textOrEmpty(option.value);
            if (!query.length || family.toLocaleLowerCase().indexOf(query) !== -1)
                filtered.push(option);

        }
        filteredFontFamilyOptions = filtered;
    }

    function isMonospaceFamily(family) {
        fontInfoProbe.font = Qt.font({
            "family": family
        });
        return fontInfoProbe.fixedPitch;
    }

    function effectiveCustomColor(value) {
        var color = textOrEmpty(value).trim();
        return color.length ? color : "#eff0f1";
    }

    function colorToConfigValue(color) {
        function componentToHex(component) {
            var clamped = Math.max(0, Math.min(255, Math.round(component * 255)));
            var hex = clamped.toString(16);
            return hex.length === 1 ? "0" + hex : hex;
        }

        var red = componentToHex(color.r);
        var green = componentToHex(color.g);
        var blue = componentToHex(color.b);
        var alpha = componentToHex(color.a);
        if (alpha === "ff")
            return "#" + red + green + blue;

        return "#" + red + green + blue + alpha;
    }

    onCfg_textAlignmentChanged: alignmentField.currentIndex = alignmentIndex(cfg_textAlignment)
    onCfg_fontFamilyChanged: {
        refreshFontFamilyOptions(cfg_fontFamily);
    }
    onCfg_useMonospaceFontChanged: refreshFontFamilyOptions(cfg_fontFamily)
    onFontFamilyFilterChanged: refreshFilteredFontFamilyOptions()
    Component.onCompleted: {
        refreshFontFamilyOptions(cfg_fontFamily);
    }

    Binding {
        target: formLayout
        property: "implicitWidth"
        value: formLayout.width
        when: formLayout.width > 0
        restoreMode: Binding.RestoreBinding
    }

    QtObject {
        id: fontFamilyValue

        property string value
    }

    QtObject {
        id: customColorValue

        property string value
    }

    FontInfo {
        id: fontInfoProbe
    }

    QQC2.Label {
        Kirigami.FormData.isSection: true
        text: ""
    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Command:")
        Layout.fillWidth: true
        spacing: formLayout.fieldIndent

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.TextField {
            id: commandField

            Layout.fillWidth: true
            placeholderText: formLayout.l10n("bash -lc '/path/to/script.sh'")
        }

        QQC2.Button {
            id: editButton

            icon.name: "document-edit"
            text: formLayout.l10n("Edit")
            enabled: formLayout.canEditPath(commandField.text)
            onClicked: formLayout.openConfiguredFile(commandField.text)
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
            id: intervalField

            from: 1
            to: 86400
            editable: true
        }

    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Width mode:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: fillWidthCheck

            text: formLayout.l10n("Fill available panel space")
        }

    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Text align:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.ComboBox {
            id: alignmentField

            textRole: "text"
            model: [{
                "text": formLayout.l10n("Left"),
                "value": "left"
            }, {
                "text": formLayout.l10n("Center"),
                "value": "center"
            }, {
                "text": formLayout.l10n("Right"),
                "value": "right"
            }]
            currentIndex: alignmentIndex(cfg_textAlignment)
            onCurrentIndexChanged: cfg_textAlignment = alignmentValue(currentIndex)
        }

    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Padding:")
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

    Item {
        Kirigami.FormData.isSection: true
        implicitHeight: Kirigami.Units.gridUnit
    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Font size:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: customFontSizeCheck

            text: formLayout.l10n("Override font size")
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
        Kirigami.FormData.label: formLayout.l10n("Font family:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: useMonospaceFontCheck

            text: formLayout.l10n("Use fixed-width font")
        }

    }

    RowLayout {
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: customFontFamilyCheck

            text: formLayout.l10n("Override font family")
        }

    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.Button {
            id: fontFamilyField

            Layout.fillWidth: true
            enabled: customFontFamilyCheck.checked
            text: formLayout.cfg_fontFamily.length ? formLayout.cfg_fontFamily : formLayout.l10n("Select font")
            onClicked: fontFamilyPopup.open()

            QQC2.Popup {
                id: fontFamilyPopup

                y: fontFamilyField.height
                width: fontFamilyField.width
                padding: Kirigami.Units.smallSpacing
                onOpened: {
                    formLayout.fontFamilyFilter = "";
                    fontFamilySearchField.forceActiveFocus();
                    fontFamilySearchField.selectAll();
                }
                onClosed: formLayout.fontFamilyFilter = ""

                contentItem: ColumnLayout {
                    spacing: Kirigami.Units.smallSpacing

                    QQC2.TextField {
                        id: fontFamilySearchField

                        Layout.fillWidth: true
                        placeholderText: formLayout.l10n("Search fonts")
                        text: formLayout.fontFamilyFilter
                        onTextChanged: formLayout.fontFamilyFilter = text
                    }

                    ListView {
                        id: fontFamilyListView

                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(contentHeight, Kirigami.Units.gridUnit * 12)
                        clip: true
                        model: formLayout.filteredFontFamilyOptions
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: QQC2.ItemDelegate {
                            required property var modelData

                            width: ListView.view.width
                            text: modelData.text
                            highlighted: modelData.value === formLayout.cfg_fontFamily
                            onClicked: {
                                fontFamilyValue.value = modelData.value;
                                fontFamilyPopup.close();
                            }
                        }

                    }

                }

            }

        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        Item {
            Layout.preferredWidth: formLayout.trailingActionWidth
        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

    }

    RowLayout {
        Kirigami.FormData.label: formLayout.l10n("Text color:")
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.CheckBox {
            id: customColorCheck

            text: formLayout.l10n("Override theme text color")
        }

    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 0

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

        QQC2.Button {
            id: customColorField

            Layout.preferredWidth: Kirigami.Units.gridUnit * 10
            enabled: customColorCheck.checked
            onClicked: colorDialog.open()

            contentItem: Item {
                implicitWidth: colorSwatch.implicitWidth
                implicitHeight: colorSwatch.implicitHeight

                Rectangle {
                    id: colorSwatch

                    anchors.centerIn: parent
                    implicitWidth: Kirigami.Units.gridUnit * 2
                    implicitHeight: Kirigami.Units.gridUnit
                    radius: Kirigami.Units.smallSpacing / 2
                    color: formLayout.effectiveCustomColor(formLayout.cfg_customColor)
                    border.width: 1
                    border.color: Kirigami.Theme.textColor
                }

            }

        }

        ColorDialog {
            id: colorDialog

            title: formLayout.l10n("Text color:")
            selectedColor: formLayout.effectiveCustomColor(formLayout.cfg_customColor)
            onAccepted: customColorValue.value = formLayout.colorToConfigValue(selectedColor)
        }

        Item {
            Layout.preferredWidth: formLayout.fieldIndent
        }

    }

}
