pragma Singleton

import QtQuick
import Quickshell.Services.SystemTray

QtObject {
    id: root

    readonly property SystemTrayItem trayItem: SystemTray.items.values.find(item => item.id.toLowerCase() === "fcitx") ?? null
    readonly property string trayIcon: trayItem?.icon ?? ""
    readonly property bool connected: DMSService.isConnected
    readonly property bool available: trayItem !== null && connected
    property bool active: false
    property int requestId: 0

    onTrayIconChanged: refresh()
    onAvailableChanged: refresh()

    function refresh() {
        const token = ++requestId;
        if (!available) {
            active = false;
            return;
        }
        DMSService.dbusCall("session", "org.fcitx.Fcitx5", "/controller", "org.fcitx.Fcitx.Controller1", "State", [], response => {
            if (token !== requestId || response.error)
                return;
            active = response.result?.values?.[0] === 2;
        });
    }

    function toggle() {
        if (!available)
            return;
        DMSService.dbusCall("session", "org.fcitx.Fcitx5", "/controller", "org.fcitx.Fcitx.Controller1", "Toggle", [], response => {
            if (!response.error)
                refresh();
        });
    }
}
