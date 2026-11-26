// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar
import "../Shared/I18n.js" as L

Item {
    id: root
    property string currentTab: "calendar"
    signal tabSelected(string tab)
    height: Constants.bottomNavigationHeight
    Rectangle {
        anchors.top: parent.top
        width: parent.width
        height: Constants.borderWidth
        color: Constants.divider
    }
    Repeater {
        model: [
            {
                key: "calendar",
                title: L.tr("Calendar", Qt.uiLanguage),
                iconName: "calendar"
            },
            {
                key: "important",
                title: L.tr("Important days", Qt.uiLanguage),
                iconName: "star"
            }
        ]
        CalendarToolButton {
            required property int index
            required property var modelData
            x: index * root.width / 2
            width: root.width / 2
            y: Constants.borderWidth
            height: Math.max(0, root.height - y)
            active: root.currentTab === modelData.key
            text: modelData.title
            icon.source: "../../assets/svg/" + modelData.iconName + ".svg"
            display: AbstractButton.TextUnderIcon
            onClicked: root.tabSelected(modelData.key)
        }
    }
}
