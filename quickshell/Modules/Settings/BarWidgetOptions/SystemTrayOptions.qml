import QtQuick
import Quickshell.Services.SystemTray
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Common
import qs.Modules.Settings.Widgets

Column {
    id: root

    property var page: null
    property string pendingIconKey: ""

    readonly property bool inlineExpansion: page.value("trayUseInlineExpansion")
    readonly property bool autoOverflow: page.value("trayAutoOverflow")
    readonly property bool trayTinted: ["primary", "secondary"].includes(SettingsData.systemTrayIconTintMode || "none")

    readonly property var trayItems: TrayMenuManager.sortByPreferredOrder(TrayMenuManager.filterEnvHidden(SystemTray.items.values), SessionData.trayItemOrder)

    readonly property var iconScales: root.page.value("trayIconScales") ?? ({})

    readonly property var iconOverrides: root.page.value("trayIconOverrides") ?? ({})

    function setIconOverride(key, value) {
        const icons = Object.assign({}, iconOverrides);
        if (value)
            icons[key] = value;
        else
            delete icons[key];
        root.page.set("trayIconOverrides", icons);
    }

    function setIconScale(key, value) {
        const scales = Object.assign({}, iconScales);
        if (value === 100)
            delete scales[key];
        else
            scales[key] = value;
        root.page.set("trayIconScales", scales);
    }

    function reorderItems(indices) {
        const keys = trayItems.map(item => TrayMenuManager.getTrayItemKey(item, trayItems));
        const reordered = indices.map(index => keys[index]);
        const liveKeys = new Set(keys);
        let next = 0;
        const order = SessionData.trayItemOrder.map(key => liveKeys.has(key) ? reordered[next++] : key);
        SessionData.setTrayItemOrder(order.concat(reordered.slice(next)));
    }

    width: parent?.width ?? 0
    spacing: Theme.spacingL

    FileBrowserModal {
        id: iconFileBrowser
        browserTitle: I18n.tr("Select an image file...")
        bucket: "logo"
        filters: ["*.svg", "*.png", "*.jpg", "*.jpeg", "*.webp"]
        onAccepted: paths => {
            if (!root.pendingIconKey || !paths.length)
                return;
            const path = paths[0];
            const url = path.startsWith("file://") ? path : "file://" + path.split("/").map(encodeURIComponent).join("/");
            root.setIconOverride(root.pendingIconKey, url);
            root.pendingIconKey = "";
        }
    }

    SettingsCard {
        settingKey: "barWidgetTray"

        SettingsToggleRow {
            text: I18n.tr("Use inline expansion")
            description: I18n.tr("Hidden icons expand in place instead of in a popup", "system tray inline expansion toggle description")
            checked: root.inlineExpansion
            onToggled: checked => root.page.set("trayUseInlineExpansion", checked)
        }

        SettingsToggleRow {
            text: I18n.tr("Single-line popup")
            enabled: !root.inlineExpansion
            checked: root.page.value("trayPopupSingleLine")
            onToggled: checked => root.page.set("trayPopupSingleLine", checked)
        }

        SettingsToggleRow {
            text: I18n.tr("Auto overflow")
            checked: root.autoOverflow
            onToggled: checked => root.page.set("trayAutoOverflow", checked)
        }

        SettingsSliderRow {
            resetStore: root.page
            resetKeys: ["trayMaxVisibleItems"]
            text: I18n.tr("Max visible")
            unit: ""
            minimumLabel: I18n.tr("Auto")
            enabled: root.autoOverflow
            value: root.page.value("trayMaxVisibleItems")
            minimum: 0
            maximum: 20
            onSliderValueChanged: newValue => root.page.set("trayMaxVisibleItems", newValue)
        }

        SettingsSliderRow {
            resetStore: root.page
            resetKeys: ["trayIconSpacing"]
            text: I18n.tr("Icon spacing")
            value: root.page.value("trayIconSpacing")
            minimum: 0
            maximum: 20
            unit: "px"
            onSliderValueChanged: newValue => root.page.set("trayIconSpacing", newValue)
        }

        SettingsButtonGroupRow {
            readonly property var modes: ["none", "monochrome", "primary", "secondary"]

            settingKey: "trayIconTint"
            tags: ["tray", "icon", "tint", "monochrome", "system tray", "color"]
            text: I18n.tr("Tray icon tint")
            resetKeys: ["systemTrayIconTintMode"]
            model: [I18n.tr("None"), I18n.tr("Monochrome"), I18n.tr("Primary"), I18n.tr("Secondary")]
            currentIndex: Math.max(0, modes.indexOf(SettingsData.systemTrayIconTintMode || "none"))
            onSelectionChanged: (index, selected) => {
                if (!selected)
                    return;
                SettingsData.set("systemTrayIconTintMode", modes[index]);
            }
        }

        SettingsSliderRow {
            text: I18n.tr("Tint saturation")
            tags: ["tray", "tint", "saturation"]
            visible: root.trayTinted
            resetKeys: ["systemTrayIconTintSaturation"]
            value: SettingsData.systemTrayIconTintSaturation ?? 50
            minimum: 0
            maximum: 100
            onSliderDragFinished: finalValue => SettingsData.set("systemTrayIconTintSaturation", finalValue)
        }

        SettingsSliderRow {
            text: I18n.tr("Tint strength")
            tags: ["tray", "tint", "strength"]
            visible: root.trayTinted
            resetKeys: ["systemTrayIconTintStrength"]
            value: SettingsData.systemTrayIconTintStrength ?? 135
            minimum: 0
            maximum: 200
            onSliderDragFinished: finalValue => SettingsData.set("systemTrayIconTintStrength", finalValue)
        }
    }

    SettingsCard {
        settingKey: "barWidgetTrayOrder"
        title: I18n.tr("Tray icons")
        iconName: "swap_vert"

        SettingsRow {
            title: I18n.tr("Drag to reorder")
            subtitle: I18n.tr("Icon order is shared across system trays. Only running applications are listed.")
        }

        SettingsReorderList {
            id: trayList
            model: root.trayItems
            onReordered: indices => root.reorderItems(indices)

            delegate: SettingsReorderRow {
                id: trayRow
                required property var modelData
                readonly property string itemKey: TrayMenuManager.getTrayItemKey(modelData, root.trayItems)
                readonly property string customIcon: root.iconOverrides[itemKey] ?? ""
                readonly property bool fileIcon: customIcon.startsWith("file://")
                readonly property int scalePercent: root.iconScales[itemKey] ?? 100

                reorderList: trayList
                title: modelData.tooltipTitle || modelData.title || modelData.id
                subtitle: modelData.id
                iconName: fileIcon ? "" : customIcon
                imageSource: fileIcon ? customIcon : (customIcon ? "" : TrayMenuManager.iconSourceFor(modelData))

                DIconPicker {
                    anchors.verticalCenter: parent.verticalCenter
                    currentIcon: trayRow.fileIcon ? "" : trayRow.customIcon
                    onIconSelected: iconName => root.setIconOverride(trayRow.itemKey, iconName)
                }

                DActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "folder_open"
                    tooltipText: I18n.tr("Select an image file...")
                    onClicked: {
                        root.pendingIconKey = trayRow.itemKey;
                        iconFileBrowser.open();
                    }
                }

                DActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "undo"
                    tooltipText: I18n.tr("Restore application icon")
                    enabled: (root.iconOverrides[trayRow.itemKey] ?? "") !== ""
                    onClicked: root.setIconOverride(trayRow.itemKey, "")
                }

                DNumberStepper {
                    anchors.verticalCenter: parent.verticalCenter
                    text: trayRow.scalePercent + "%"
                    incrementEnabled: trayRow.scalePercent < 200
                    decrementEnabled: trayRow.scalePercent > 50
                    incrementTooltipText: I18n.tr("Increase icon scale")
                    decrementTooltipText: I18n.tr("Decrease icon scale")
                    onIncrement: () => root.setIconScale(trayRow.itemKey, Math.min(200, trayRow.scalePercent + 5))
                    onDecrement: () => root.setIconScale(trayRow.itemKey, Math.max(50, trayRow.scalePercent - 5))
                }

                DActionButton {
                    anchors.verticalCenter: parent.verticalCenter
                    iconName: "restart_alt"
                    tooltipText: I18n.tr("Reset to default")
                    enabled: trayRow.scalePercent !== 100
                    onClicked: root.setIconScale(trayRow.itemKey, 100)
                }
            }
        }

        SettingsRow {
            visible: root.trayItems.length === 0
            title: I18n.tr("No tray icons")
        }
    }
}
