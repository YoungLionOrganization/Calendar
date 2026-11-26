// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import Calendar

Item {
    id: root
    property real cellSpacing: Constants.monthGridSpacing
    property bool compact: false
    property int firstWeekday: Constants.firstWeekday
    height: Constants.weekdayHeaderHeight
    readonly property real cellWidth: Math.max(0, (width - 6 * cellSpacing) / 7)
    Repeater {
        model: 7
        Text {
            required property int index
            readonly property int weekday: (index + root.firstWeekday) % 7
            x: index * (root.cellWidth + root.cellSpacing)
            width: root.cellWidth
            height: root.height
            text: root.compact ? Qt.locale(Qt.uiLanguage).dayName(weekday, Locale.ShortFormat).charAt(0) : Qt.locale(Qt.uiLanguage).dayName(weekday, Locale.ShortFormat)
            font.family: Constants.fontFamily
            font.pixelSize: Math.max(1, Math.min(root.compact ? Constants.fontSizeMicro : Constants.fontSizeWeekday, width * 0.85))
            font.weight: Constants.fontWeightMedium
            color: (Constants.nonWorkingDays & (1 << weekday)) ? Constants.primary : Constants.calendarWeekdayText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
