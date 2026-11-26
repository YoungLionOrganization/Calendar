// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import Calendar
import "../Shared/DateUtils.mjs" as DateUtils
import "../Events/EventLogic.mjs" as Events

Item {
    id: root
    property int yearNumber: 2026
    property int monthIndex: 0
    property var selectedDate: new Date()
    property var referenceDate: new Date()
    property var days: null
    property var eventColors: ({})
    property int firstWeekday: Constants.firstWeekday
    property bool showEventMarkers: true
    signal daySelected(var date)
    signal createRequested(var date)
    readonly property var firstDate: DateUtils.makeDate(yearNumber, monthIndex, 1)
    readonly property int startOffset: (firstDate.getDay() - firstWeekday + 7) % 7
    readonly property real cellWidth: Math.max(0, (width - 6 * Constants.monthGridSpacing) / 7)
    readonly property real cellHeight: Math.max(0, (height - 5 * Constants.monthGridSpacing) / 6)
    Item {
        anchors.fill: parent
        Repeater {
            model: 42
            CalendarDayItem {
                required property int index
                readonly property var entry: root.days ? root.days[index] : null
                readonly property var cellDate: entry ? Events.date(entry.key)
                                                       : DateUtils.addDays(root.firstDate, index - root.startOffset)
                x: (index % 7) * (root.cellWidth + Constants.monthGridSpacing)
                y: Math.floor(index / 7) * (root.cellHeight + Constants.monthGridSpacing)
                width: root.cellWidth
                height: root.cellHeight
                day: cellDate.getDate()
                eventColors: root.showEventMarkers && inMonth && entry
                    ? entry.markers.map(category => (root.eventColors[category] || root.eventColors.other)[0])
                    : []
                inMonth: cellDate.getMonth() === root.monthIndex
                weekend: (Constants.nonWorkingDays & (1 << cellDate.getDay())) !== 0
                today: inMonth && DateUtils.sameDate(cellDate, root.referenceDate)
                selected: inMonth && DateUtils.sameDate(cellDate, root.selectedDate)
                onClicked: root.daySelected(cellDate)
                onHeld: root.createRequested(cellDate)
            }
        }
    }
}
