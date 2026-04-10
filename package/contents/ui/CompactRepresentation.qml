import QtQml
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

PlasmaCore.ToolTipArea {
    id: compactRoot

    function horizontalAlignmentFor(value) {
        if (value === "right")
            return Text.AlignRight;

        return Text.AlignLeft;
    }

    active: true
    mainText: ""
    subText: root.tooltipText
    textFormat: Text.PlainText
    Layout.fillWidth: root.fillWidthSetting
    Layout.fillHeight: true
    Layout.minimumWidth: root.fillWidthSetting ? 50 : textLabel.implicitWidth + (root.padding * 2)
    Layout.preferredWidth: root.fillWidthSetting ? 200 : textLabel.implicitWidth + (root.padding * 2)
    Layout.maximumWidth: root.fillWidthSetting ? Number.POSITIVE_INFINITY : textLabel.implicitWidth + (root.padding * 2)
    Layout.minimumHeight: textLabel.implicitHeight + (root.padding * 2)
    Layout.preferredHeight: textLabel.implicitHeight + (root.padding * 2)
    implicitWidth: root.fillWidthSetting ? 200 : textLabel.implicitWidth + (root.padding * 2)
    implicitHeight: textLabel.implicitHeight + (root.padding * 2)

    PlasmaComponents3.Label {
        id: textLabel

        anchors.horizontalCenter: root.textAlignment === "center" ? parent.horizontalCenter : undefined
        anchors.left: root.textAlignment === "left" ? parent.left : undefined
        anchors.right: root.textAlignment === "right" ? parent.right : undefined
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.padding
        anchors.rightMargin: root.padding
        width: Math.min(implicitWidth, parent.width - (root.padding * 2))
        horizontalAlignment: compactRoot.horizontalAlignmentFor(root.textAlignment)
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
