// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Rectangle {
    id: root
    property int day: 1
    property bool selected: false
    property bool today: false
    property bool inMonth: true
    property bool weekend: false
    property var eventColors: []
    signal clicked
    signal held
    color: !inMonth ? Constants.calendarOutsideMonthBackground : today ? Constants.calendarTodayBackground : selected ? Constants.calendarDaySelected : Constants.allDayBackground
    radius: Constants.radiusCalendarCell
    border.width: selected ? Constants.borderWidthStrong : Constants.borderWidth
    border.color: today ? Constants.calendarTodayBorder : selected ? Constants.calendarDaySelectedBorder : Constants.calendarGridLine
    Label {
        anchors.centerIn: parent
        text: root.day
        font.family: Constants.fontFamily
        font.pixelSize: Math.max(1, Math.min(Constants.fontSizeDayNumber, root.width * 0.7, root.height * 0.8))
        font.weight: root.today || root.selected ? Constants.fontWeightSemibold : Constants.fontWeightNormal
        color: !root.inMonth ? Constants.calendarOutsideMonthText : root.today ? Constants.calendarTodayText : root.selected ? Constants.calendarDaySelectedText : root.weekend ? Constants.primary : Constants.textPrimary
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Constants.spacing2xs
        spacing: Constants.eventDotSpacing
        visible: root.height >= Constants.fontSizeDayNumber + Constants.eventDotSize + 3 * Constants.spacing2xs
        Repeater {
            model: root.eventColors.slice(0, Constants.maxVisibleMobileEventDots)
            Rectangle {
                required property var modelData
                width: Constants.eventDotSize
                height: width
                radius: width / 2
                color: modelData
            }
        }
    }
    TapHandler {
        enabled: root.enabled && root.inMonth
        onTapped: root.clicked()
        onLongPressed: root.held()
    }
}
