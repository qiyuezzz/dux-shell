import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import qs.Common
import qs.DCommon.Widgets

Item {
    id: root

    property var tray: null
    property var trayItem: null
    property string source: ""
    readonly property string customIcon: tray ? tray.iconOverrideFor(trayItem) : ""
    readonly property bool fileIcon: customIcon.startsWith("file://")
    readonly property bool symbolIcon: customIcon !== "" && !fileIcon
    property real iconSize: tray ? tray.iconSizeFor(trayItem) : Theme.iconSizeSmall
    property bool iconTintEnabled: tray ? tray.trayIconTintEnabled : false
    property real iconSaturation: tray ? tray.trayIconSaturation : 0
    property real iconColorization: tray ? tray.trayIconColorization : 0
    property color iconTintColor: tray ? tray.trayIconTintColor : "transparent"
    property color fallbackTextColor: tray ? (tray.trayTextColor ?? Theme.widgetTextColor) : Theme.widgetTextColor
    property real fallbackTextSize: 10
    property string fallbackSource: ""

    onSourceChanged: fallbackSource = ""
    onCustomIconChanged: fallbackSource = ""

    DIcon {
        anchors.centerIn: parent
        visible: root.symbolIcon
        name: root.customIcon
        size: root.iconSize
        color: root.iconTintEnabled ? root.iconTintColor : root.fallbackTextColor
    }

    IconImage {
        id: iconImg
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.fallbackSource || (root.fileIcon ? root.customIcon : root.source)
        asynchronous: true
        onStatusChanged: {
            if (status !== Image.Error || root.fallbackSource)
                return;
            if (root.fileIcon) {
                root.fallbackSource = root.source;
                return;
            }
            const requested = root.source;
            TrayMenuManager.resolveIconFallback(root.trayItem?.icon, url => {
                if (root.source !== requested)
                    return;
                root.fallbackSource = url;
            });
        }
        smooth: true
        mipmap: true
        visible: !root.symbolIcon && status === Image.Ready
        layer.enabled: root.iconTintEnabled
        layer.effect: MultiEffect {
            saturation: root.iconSaturation
            colorization: root.iconColorization
            colorizationColor: root.iconTintColor
        }
    }

    StyledText {
        anchors.centerIn: parent
        visible: !root.symbolIcon && !iconImg.visible
        text: {
            const itemId = root.trayItem?.id || "";
            if (!itemId)
                return "?";
            return itemId.charAt(0).toUpperCase();
        }
        font.pixelSize: root.fallbackTextSize
        color: root.fallbackTextColor
    }
}
