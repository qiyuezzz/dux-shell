import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.DCommon.Widgets

BasePill {
    id: root

    onClicked: InputMethodService.toggle()

    content: Component {
        Item {
            implicitWidth: root.isVerticalOrientation ? root.contentThickness : label.implicitWidth
            implicitHeight: root.contentThickness

            StyledText {
                id: label
                anchors.centerIn: parent
                text: InputMethodService.available ? (InputMethodService.active ? I18n.tr("中") : I18n.tr("英")) : I18n.tr("—")
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: root.contentColor
            }
        }
    }
}
