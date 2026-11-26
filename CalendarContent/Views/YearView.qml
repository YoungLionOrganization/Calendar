// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Item {
    id: root
    property int yearNumber: 2026
    property var referenceDate: new Date()
    signal yearSelected(int year)
    signal monthSelected(int monthIndex)
    PeriodNavigation {
        id: navigation
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        titleText: String(root.yearNumber)
        largeTitle: true
        previousEnabled: root.yearNumber > 1900
        nextEnabled: root.yearNumber < 2100
        onPreviousRequested: yearSwipeView.step(-1)
        onNextRequested: yearSwipeView.step(1)
    }
    PeriodSwipeView {
        id: yearSwipeView
        anchors.top: navigation.bottom
        anchors.topMargin: Constants.spacingSm
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(0, root.height - y)
        period: root.yearNumber
        minimumPeriod: 1900
        maximumPeriod: 2100
        onPeriodRequested: function (value) {
            root.yearSelected(value);
        }
        pageDelegate: Component {
            YearGridPage {
                referenceDate: root.referenceDate
                onMonthSelected: function (monthIndex) {
                    root.monthSelected(monthIndex);
                }
            }
        }
    }
}
