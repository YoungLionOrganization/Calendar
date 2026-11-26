// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Item {
    id: root
    property int yearNumber: 2026
    property int monthIndex: 0
    property var selectedDate: new Date()
    property var referenceDate: new Date()
    property var events: []
    property var cache: null
    property var eventColors: ({})
    property int firstWeekday: 1
    property bool sideDetails: width >= 880
    readonly property real gridRightMargin: sideDetails ? Math.min(300, width * 0.28) + Constants.spacingMd : 0
    property bool showEventMarkers: true
    signal eventSelected(var eventData)
    signal addRequested
    signal createRequested(var date)
    signal monthSelected(int year, int month)
    signal daySelected(var date)
    readonly property bool detailsVisible: height >= Constants.monthHeaderHeight + Constants.weekdayHeaderHeight + 6 * Constants.fontSizeDayNumber + Constants.controlHeightMd + Constants.spacingLg
    PeriodNavigation {
        id: navigation
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: root.gridRightMargin
        titleText: Qt.locale(Qt.uiLanguage).standaloneMonthName(root.monthIndex, Locale.LongFormat) + " " + root.yearNumber
        previousEnabled: monthSwipeView.period > monthSwipeView.minimumPeriod
        nextEnabled: monthSwipeView.period < monthSwipeView.maximumPeriod
        onPreviousRequested: monthSwipeView.step(-1)
        onNextRequested: monthSwipeView.step(1)
    }
    WeekdayHeader {
        id: weekdays
        firstWeekday: root.firstWeekday
        anchors.top: navigation.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: root.gridRightMargin
    }
    PeriodSwipeView {
        id: monthSwipeView
        anchors.top: weekdays.bottom
        anchors.topMargin: Constants.spacingXs
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.rightMargin: root.gridRightMargin
        height: Math.max(0, root.height - y - (root.sideDetails ? 0 : detailsPanel.height + (root.detailsVisible ? Constants.spacingSm : 0)))
        period: root.yearNumber * 12 + root.monthIndex
        minimumPeriod: 1900 * 12
        maximumPeriod: 2100 * 12 + 11
        onPeriodRequested: function (value) {
            root.monthSelected(Math.floor(value / 12), value % 12);
        }
        pageDelegate: Component {
            MonthGridPage {
                property int pagePeriod: 2026 * 12
                yearNumber: Math.floor(pagePeriod / 12)
                monthIndex: pagePeriod % 12
                selectedDate: root.selectedDate
                referenceDate: root.referenceDate
                days: root.cache ? root.cache.months[pagePeriod] || null : null
                eventColors: root.eventColors
                firstWeekday: root.firstWeekday
                showEventMarkers: root.showEventMarkers
                onDaySelected: function (date) {
                    root.daySelected(date);
                }
                onCreateRequested: function (date) {
                    root.createRequested(date);
                }
            }
        }
    }
    SelectedDayPanel {
        id: detailsPanel
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.sideDetails ? root.gridRightMargin - Constants.spacingMd : root.width
        visible: root.detailsVisible || root.sideDetails
        height: root.sideDetails ? Math.max(0, root.height - navigation.height)
                                 : visible ? Math.min(Constants.calendarDayPreferredHeight * 2.5, root.height * 0.27) : 0
        selectedDate: root.selectedDate
        events: root.events
        onEventSelected: function (eventData) {
            root.eventSelected(eventData);
        }
        onAddRequested: root.addRequested()
    }
}
