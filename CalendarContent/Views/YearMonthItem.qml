// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import Calendar
import "../Shared/DateUtils.mjs" as DateUtils

Item {
    id: root
    property int monthIndex: 0
    property int yearNumber: 2026
    property var referenceDate: new Date()
    signal monthSelected(int monthIndex)
    readonly property var firstDate: DateUtils.makeDate(yearNumber, monthIndex, 1)
    readonly property int startOffset: (firstDate.getDay() - Constants.firstWeekday + 7) % 7
    readonly property int daysInMonth: DateUtils.daysInMonth(yearNumber, monthIndex)
    readonly property real dayHeight: Math.max(0, Math.min(Constants.fontSizeXs + Constants.spacingSm, (height - monthLabel.height - 2 * Constants.spacingXs) / 7))
    Text {
        id: monthLabel
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        text: Qt.locale(Qt.uiLanguage).standaloneMonthName(root.monthIndex, Locale.ShortFormat)
        font.family: Constants.fontFamily
        font.pixelSize: Constants.fontSizeLg
        font.weight: Constants.fontWeightMedium
        color: Constants.textPrimary
        elide: Text.ElideRight
    }
    WeekdayHeader {
        id: weekdays
        anchors.top: monthLabel.bottom
        anchors.topMargin: Constants.spacingXs
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.dayHeight
        cellSpacing: 0
        compact: true
    }
    Item {
        id: monthDays
        anchors.top: weekdays.bottom
        anchors.topMargin: Constants.spacingXs
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.dayHeight * 6
        Repeater {
            model: 42
            Item {
                id: cell
                required property int index
                readonly property int number: index - root.startOffset + 1
                readonly property bool validDay: number >= 1 && number <= root.daysInMonth
                readonly property bool isToday: validDay && root.yearNumber === root.referenceDate.getFullYear() && root.monthIndex === root.referenceDate.getMonth() && number === root.referenceDate.getDate()
                x: (index % 7) * width
                y: Math.floor(index / 7) * height
                width: monthDays.width / 7
                height: root.dayHeight
                Rectangle {
                    visible: cell.isToday
                    anchors.centerIn: parent
                    width: Math.max(0, Math.min(parent.width, parent.height) - Constants.spacing2xs)
                    height: width
                    radius: width / 2
                    color: Constants.primary
                }
                Text {
                    anchors.centerIn: parent
                    visible: cell.validDay
                    text: cell.number
                    font.family: Constants.fontFamily
                    font.pixelSize: Math.max(1, Math.min(Constants.fontSizeXs, cell.width * 0.72, cell.height))
                    color: cell.isToday ? Constants.textOnPrimary : cell.index % 7 >= 5 ? Constants.primary : Constants.textSecondary
                }
            }
        }
    }
    TapHandler {
        onTapped: root.monthSelected(root.monthIndex)
    }
}
