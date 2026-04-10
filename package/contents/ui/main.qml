import "../code/Localization.js" as Localization
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    readonly property string localeName: Qt.locale().name || "en_US"
    readonly property string command: String(Plasmoid.configuration.command ?? "").trim()
    readonly property int intervalSeconds: normalizedNumber(Plasmoid.configuration.intervalSeconds, 60, 1)
    readonly property bool tooltipEnabled: normalizedBool(Plasmoid.configuration.tooltipEnabled, false)
    readonly property string tooltipCommand: String(Plasmoid.configuration.tooltipCommand ?? "").trim()
    readonly property int tooltipIntervalSeconds: normalizedNumber(Plasmoid.configuration.tooltipIntervalSeconds, 60, 1)
    readonly property string tooltipDefaultText: normalizedString(Plasmoid.configuration.tooltipDefaultText, l10n("Scriptoid"))
    readonly property bool fillWidthSetting: normalizedBool(Plasmoid.configuration.fillWidth, true)
    readonly property int padding: normalizedNumber(Plasmoid.configuration.padding, 8, 0)
    readonly property bool useCustomFontSize: normalizedBool(Plasmoid.configuration.useCustomFontSize, false)
    readonly property int fontSize: normalizedNumber(Plasmoid.configuration.fontSize, 12, 1)
    readonly property bool useCustomFontFamily: normalizedBool(Plasmoid.configuration.useCustomFontFamily, false)
    readonly property string fontFamily: String(Plasmoid.configuration.fontFamily ?? "").trim()
    readonly property bool useCustomColor: normalizedBool(Plasmoid.configuration.useCustomColor, false)
    readonly property string customColor: String(Plasmoid.configuration.customColor ?? "").trim()
    readonly property string textAlignment: normalizedAlignment(Plasmoid.configuration.textAlignment)
    readonly property bool useMonospaceFont: normalizedBool(Plasmoid.configuration.useMonospaceFont, false)
    property string displayText: command.length ? l10n("Loading…") : l10n("No command set")
    property string displayMarkup: displayText
    property bool displayUsesRichText: false
    property string currentSource: ""
    property string tooltipText: tooltipEnabled ? (tooltipCommand.length ? l10n("Loading…") : tooltipDefaultText) : tooltipDefaultText
    property string currentTooltipSource: ""

    function l10n(key) {
        return Localization.translate(localeName, key, i18n(key));
    }

    function normalizedNumber(value, fallback, minimum) {
        const parsed = Number(value);
        if (!Number.isFinite(parsed))
            return fallback;

        return Math.max(minimum, Math.round(parsed));
    }

    function normalizedBool(value, fallback) {
        if (value === undefined || value === null)
            return fallback;

        if (typeof value === "boolean")
            return value;

        if (typeof value === "string") {
            const normalized = value.trim().toLowerCase();
            if (normalized === "true" || normalized === "1" || normalized === "yes" || normalized === "on")
                return true;

            if (normalized === "false" || normalized === "0" || normalized === "no" || normalized === "off")
                return false;

        }
        return Boolean(value);
    }

    function normalizedString(value, fallback) {
        const normalized = String(value ?? "").trim();
        return normalized.length ? normalized : fallback;
    }

    function normalizedAlignment(value) {
        const normalized = String(value ?? "").trim().toLowerCase();
        if (normalized === "left" || normalized === "right")
            return normalized;

        return "center";
    }

    function horizontalAlignmentFor(value) {
        if (value === "right")
            return Text.AlignRight;

        return Text.AlignLeft;
    }

    function trimOutput(text) {
        const lines = String(text ?? "").split("\n");
        while (lines.length > 0 && lines[0].trim() === "")lines.shift()
        while (lines.length > 0 && lines[lines.length - 1].trim() === "")lines.pop()
        return lines.join("\n");
    }

    function escapeHtml(text) {
        return String(text ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\n/g, "<br>").replace(/ /g, "&nbsp;");
    }

    function stripAnsi(text) {
        return String(text ?? "").replace(/\x1b\[[0-9;]*[a-zA-Z]/g, "");
    }

    function ansiToHtml(text) {
        function get256Color(index) {
            index = index & 255;
            if (index < 16) {
                const map = ["30", "31", "32", "33", "34", "35", "36", "37", "90", "91", "92", "93", "94", "95", "96", "97"];
                return colors[map[index]];
            }
            if (index < 232) {
                index -= 16;
                const r = Math.floor(index / 36);
                const g = Math.floor((index % 36) / 6);
                const b = index % 6;
                const levels = [0, 95, 135, 175, 215, 255];
                const rv = levels[r];
                const gv = levels[g];
                const bv = levels[b];
                return "#" + ((1 << 24) + (rv << 16) + (gv << 8) + bv).toString(16).slice(1);
            }
            const v = (index - 232) * 10 + 8;
            return "#" + ((1 << 24) + (v << 16) + (v << 8) + v).toString(16).slice(1);
        }

        const colors = {
            "30": "#000000",
            "31": "#ff5555",
            "32": "#50fa7b",
            "33": "#f1fa8c",
            "34": "#8be9fd",
            "35": "#ff79c6",
            "36": "#8be9fd",
            "37": "#f8f8f2",
            "90": "#6272a4",
            "91": "#ff6e6e",
            "92": "#69ff94",
            "93": "#ffffa5",
            "94": "#9aedfe",
            "95": "#ff92df",
            "96": "#a4ffff",
            "97": "#ffffff"
        };
        const source = String(text ?? "");
        const pattern = /\x1b\[([0-9;]*)m/g;
        let currentColor = "";
        let html = "";
        let hasAnsi = false;
        let lastIndex = 0;
        let match;
        while ((match = pattern.exec(source)) !== null) {
            const segment = source.slice(lastIndex, match.index);
            if (segment.length) {
                if (currentColor.length)
                    html += "<span style=\"color:" + currentColor + "\">" + escapeHtml(segment) + "</span>";
                else
                    html += escapeHtml(segment);
            }
            hasAnsi = true;
            const codes = match[1].length ? match[1].split(";").map(Number) : [0];
            for (let i = 0; i < codes.length; i++) {
                const code = codes[i];
                if (code === 0 || code === 39) {
                    currentColor = "";
                } else if (Object.prototype.hasOwnProperty.call(colors, code.toString())) {
                    currentColor = colors[code.toString()];
                } else if (code === 38) {
                    if (codes[i + 1] === 5 && i + 2 < codes.length) {
                        currentColor = get256Color(codes[i + 2]);
                        i += 2;
                    } else if (codes[i + 1] === 2 && i + 4 < codes.length) {
                        const r = codes[i + 2] & 255;
                        const g = codes[i + 3] & 255;
                        const b = codes[i + 4] & 255;
                        currentColor = "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
                        i += 4;
                    }
                }
            }
            lastIndex = pattern.lastIndex;
        }
        const tail = source.slice(lastIndex);
        if (tail.length) {
            if (currentColor.length)
                html += "<span style=\"color:" + currentColor + "\">" + escapeHtml(tail) + "</span>";
            else
                html += escapeHtml(tail);
        }
        return {
            "hasAnsi": hasAnsi,
            "html": html,
            "text": stripAnsi(source)
        };
    }

    function disconnectCurrentSource() {
        if (currentSource.length) {
            executable.disconnectSource(currentSource);
            currentSource = "";
        }
    }

    function refreshCommand() {
        if (!command.length) {
            disconnectCurrentSource();
            displayText = l10n("No command set");
            displayMarkup = displayText;
            displayUsesRichText = false;
            return ;
        }
        disconnectCurrentSource();
        currentSource = command;
        executable.connectSource(command);
    }

    function disconnectCurrentTooltipSource() {
        if (currentTooltipSource.length) {
            tooltipExecutable.disconnectSource(currentTooltipSource);
            currentTooltipSource = "";
        }
    }

    function refreshTooltipCommand() {
        if (!tooltipEnabled) {
            disconnectCurrentTooltipSource();
            tooltipText = tooltipDefaultText;
            return ;
        }
        if (!tooltipCommand.length) {
            disconnectCurrentTooltipSource();
            tooltipText = tooltipDefaultText;
            return ;
        }
        disconnectCurrentTooltipSource();
        currentTooltipSource = tooltipCommand;
        tooltipExecutable.connectSource(tooltipCommand);
    }

    function applyCommandResult(data) {
        const stdout = String(data["stdout"] ?? "");
        const stderr = String(data["stderr"] ?? "");
        const exitCode = Number(data["exit code"] ?? data["exitCode"] ?? 0);
        let nextText = trimOutput(stdout);
        if (!nextText.length)
            nextText = trimOutput(stderr);

        if (!nextText.length)
            nextText = exitCode === 0 ? l10n("No output") : l10n("Command failed");

        const formatted = ansiToHtml(nextText);
        displayText = formatted.text;
        displayMarkup = formatted.hasAnsi ? formatted.html : formatted.text;
        displayUsesRichText = formatted.hasAnsi;
    }

    function applyTooltipResult(data) {
        const stdout = String(data["stdout"] ?? "");
        const stderr = String(data["stderr"] ?? "");
        const exitCode = Number(data["exit code"] ?? data["exitCode"] ?? 0);
        let nextText = trimOutput(stdout);
        if (!nextText.length)
            nextText = trimOutput(stderr);

        if (!nextText.length)
            nextText = exitCode === 0 ? l10n("No output") : l10n("Command failed");

        tooltipText = stripAnsi(nextText);
    }

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    Plasmoid.icon: "utilities-terminal"
    toolTipMainText: ""
    toolTipSubText: ""
    toolTipTextFormat: Text.PlainText
    Layout.fillWidth: fillWidthSetting
    Layout.fillHeight: true
    Layout.minimumWidth: fillWidthSetting ? 50 : textLabel.implicitWidth + (padding * 2)
    Layout.preferredWidth: fillWidthSetting ? 200 : textLabel.implicitWidth + (padding * 2)
    Layout.maximumWidth: fillWidthSetting ? Number.POSITIVE_INFINITY : textLabel.implicitWidth + (padding * 2)
    Layout.minimumHeight: textLabel.implicitHeight + (padding * 2)
    Layout.preferredHeight: textLabel.implicitHeight + (padding * 2)
    implicitWidth: fillWidthSetting ? 200 : textLabel.implicitWidth + (padding * 2)
    implicitHeight: textLabel.implicitHeight + (padding * 2)
    Component.onCompleted: {
        refreshCommand();
        refreshTooltipCommand();
    }
    onCommandChanged: {
        displayText = command.length ? l10n("Loading…") : l10n("No command set");
        displayMarkup = displayText;
        displayUsesRichText = false;
        refreshCommand();
    }
    onIntervalSecondsChanged: refreshCommand()
    onTooltipEnabledChanged: {
        tooltipText = tooltipEnabled ? (tooltipCommand.length ? l10n("Loading…") : tooltipDefaultText) : tooltipDefaultText;
        refreshTooltipCommand();
    }
    onTooltipCommandChanged: {
        tooltipText = tooltipEnabled ? (tooltipCommand.length ? l10n("Loading…") : tooltipDefaultText) : tooltipDefaultText;
        refreshTooltipCommand();
    }
    onTooltipIntervalSecondsChanged: refreshTooltipCommand()
    onTooltipDefaultTextChanged: {
        if (!tooltipEnabled)
            tooltipText = tooltipDefaultText;

    }

    P5Support.DataSource {
        id: executable

        engine: "executable"
        interval: root.intervalSeconds * 1000
        onNewData: function(sourceName, data) {
            root.applyCommandResult(data);
            if (root.currentSource !== sourceName)
                disconnectSource(sourceName);

        }
    }

    P5Support.DataSource {
        id: tooltipExecutable

        engine: "executable"
        interval: root.tooltipIntervalSeconds * 1000
        onNewData: function(sourceName, data) {
            root.applyTooltipResult(data);
            if (root.currentTooltipSource !== sourceName)
                disconnectSource(sourceName);

        }
    }

    PlasmaCore.ToolTipArea {
        id: textToolTipArea

        anchors.horizontalCenter: root.textAlignment === "center" ? parent.horizontalCenter : undefined
        anchors.left: root.textAlignment === "left" ? parent.left : undefined
        anchors.right: root.textAlignment === "right" ? parent.right : undefined
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        width: Math.min(textLabel.implicitWidth, parent.width - (root.padding * 2))
        height: textLabel.implicitHeight
        active: true
        mainText: ""
        subText: root.tooltipText
        textFormat: Text.PlainText

        PlasmaComponents3.Label {
            id: textLabel

            anchors.fill: parent
            horizontalAlignment: root.horizontalAlignmentFor(root.textAlignment)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
            textFormat: root.displayUsesRichText ? Text.RichText : Text.PlainText
            text: root.displayUsesRichText ? root.displayMarkup : root.displayText
            font.family: {
                if (root.useCustomFontFamily && root.fontFamily.length > 0)
                    return root.fontFamily;

                if (root.useMonospaceFont)
                    return Kirigami.Theme.fixedWidthFont.family;

                return Kirigami.Theme.defaultFont.family;
            }
            font.pixelSize: root.useCustomFontSize ? root.fontSize : Kirigami.Theme.defaultFont.pixelSize

            Binding on color {
                when: root.useCustomColor && root.customColor.length > 0
                value: root.customColor
            }

        }

    }

}
