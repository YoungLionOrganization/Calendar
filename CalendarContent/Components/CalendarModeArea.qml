// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar
import "../Shared/I18n.js" as L

Item {
    id: root
    property bool vertical: false
    property bool expanded: false
    property string currentView: "year"
    signal viewSelected(string viewName)
    readonly property int buttonHeight: Constants.controlHeightLg + Constants.iconSizeMd
    readonly property int expandedHeight: (vertical ? 4 : 1) * (buttonHeight + Constants.spacingSm)
    height: expanded ? expandedHeight : 0
    clip: true
    enabled: expanded
    opacity: expanded ? 1 : 0
    Behavior on height {
        NumberAnimation {
            duration: Constants.durationNormal
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: Constants.durationFast
        }
    }
    Item {
        id: buttonArea
        width: root.width
        height: root.expandedHeight
        Repeater {
            model: [
                {
                    key: "year",
                    title: L.tr("Year", Qt.uiLanguage),
                    glyph: "view-year"
                },
                {
                    key: "month",
                    title: L.tr("Month", Qt.uiLanguage),
                    glyph: "view-month"
                },
                {
                    key: "week",
                    title: L.tr("Week", Qt.uiLanguage),
                    glyph: "view-week"
                },
                {
                    key: "agenda",
                    title: L.tr("Agenda", Qt.uiLanguage),
                    glyph: "view-agenda"
                }
            ]
            CalendarToolButton {
                required property int index
                required property var modelData
                readonly property real cellWidth: Math.max(0, (buttonArea.width - 3 * Constants.spacingXs) / 4)
                x: root.vertical ? 0 : index * (cellWidth + Constants.spacingXs)
                y: Constants.spacingXs + (root.vertical ? index * (root.buttonHeight + Constants.spacingSm) : 0)
                width: root.vertical ? buttonArea.width : cellWidth
                height: root.buttonHeight
                text: modelData.title
                icon.source: "../../assets/svg/" + modelData.glyph + ".svg"
                display: AbstractButton.TextUnderIcon
                active: root.currentView === modelData.key
                onClicked: root.viewSelected(modelData.key)
            }
        }
    }
}
