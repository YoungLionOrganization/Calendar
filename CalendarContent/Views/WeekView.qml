// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar
import "../Shared/DateUtils.mjs" as Dates
import "../Shared/EventData.mjs" as Events
import "../Shared/I18n.js" as L

Item {
    id: root
    property var selectedDate: new Date()
    property var referenceDate: new Date()
    property var events: []
    signal previousRequested
    signal nextRequested
    signal daySelected(var date)
    signal eventSelected(var eventData)
    signal createRequested(var date, int minute)

    property int firstWeekday: Constants.firstWeekday
    readonly property var firstDay: Dates.addDays(selectedDate, -((selectedDate.getDay() - firstWeekday + 7) % 7))
    readonly property real gutter: Math.min(Constants.timelineTimeColumnWidth, width / 4)
    readonly property real hourHeight: Constants.timelineHourHeight
    // On phones the timeline scrolls sideways instead of crushing seven columns.
    readonly property real dayWidth: Math.max(Constants.touchTargetSize + Constants.spacing2xl, (width - gutter) / 7)
    readonly property real gridWidth: 7 * dayWidth
    readonly property int allDayRows: {
        let result = 0;
        for (let i = 0; i < 7; ++i)
            result = Math.max(result, Events.dayEvents(events, Dates.addDays(firstDay, i), true).length);
        return result;
    }
    property var clock: new Date()
    Timer {
        interval: 60000
        repeat: true
        running: root.visible
        onTriggered: root.clock = new Date()
    }

    PeriodNavigation {
        id: navigation
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        titleText: Qt.locale(Qt.uiLanguage).toString(root.firstDay, "d MMM") + " – " + Qt.locale(Qt.uiLanguage).toString(Dates.addDays(root.firstDay, 6), "d MMM yyyy")
        previousEnabled: Dates.addDays(root.selectedDate, -7).getFullYear() >= 1900
        nextEnabled: Dates.addDays(root.selectedDate, 7).getFullYear() <= 2100
        onPreviousRequested: root.previousRequested()
        onNextRequested: root.nextRequested()
    }
    Text {
        id: demoLabel
        anchors.top: navigation.bottom
        anchors.left: parent.left
        text: L.tr("Scroll horizontally for all days", Qt.uiLanguage)
        color: Constants.textTertiary
        font.family: Constants.fontFamily
        font.pixelSize: Constants.fontSizeCaption
        width: parent.width
        elide: Text.ElideRight
    }
    Item {
        id: dateHeader
        anchors.top: demoLabel.bottom
        anchors.topMargin: Constants.spacingXs
        anchors.left: parent.left
        anchors.right: parent.right
        height: Constants.weekdayHeaderHeight + Constants.dayNumberSize
        Rectangle {
            anchors.fill: parent
            color: Constants.background
        }
        Item {
            anchors.left: parent.left
            anchors.leftMargin: root.gutter
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            clip: true
            Item {
                x: -timeline.contentX
                width: root.gridWidth
                height: parent.height
                Repeater {
                    model: 7
                    Item {
                        id: dayHeader
                        required property int index
                        readonly property var dayDate: Dates.addDays(root.firstDay, index)
                        readonly property bool isToday: Dates.sameDate(dayDate, root.clock)
                        readonly property bool isSelected: Dates.sameDate(dayDate, root.selectedDate)
                        x: index * root.dayWidth
                        width: root.dayWidth
                        height: dateHeader.height
                        Text {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.locale(Qt.uiLanguage).toString(dayHeader.dayDate, "ddd")
                            font.family: Constants.fontFamily
                            font.pixelSize: Constants.fontSizeWeekday
                            color: (Constants.nonWorkingDays & (1 << ((root.firstWeekday + dayHeader.index) % 7))) || dayHeader.isToday ? Constants.primary : Constants.textSecondary
                        }
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Constants.dayNumberSize
                            height: width
                            radius: width / 2
                            color: dayHeader.isToday ? Constants.calendarTodayBackground : dayHeader.isSelected ? Constants.calendarDaySelected : "transparent"
                            border.width: dayHeader.isSelected && !dayHeader.isToday ? Constants.borderWidth : 0
                            border.color: Constants.primary
                            Text {
                                anchors.centerIn: parent
                                text: dayHeader.dayDate.getDate()
                                color: dayHeader.isToday ? Constants.calendarTodayText : Constants.textPrimary
                                font.family: Constants.fontFamily
                                font.pixelSize: Constants.fontSizeDayNumber
                                font.weight: Constants.fontWeightSemibold
                            }
                        }
                        TapHandler {
                            onTapped: root.daySelected(dayHeader.dayDate)
                        }
                    }
                }
            }
        }
    }
    Rectangle {
        id: allDayHeader
        anchors.top: dateHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(Constants.allDayHeaderMinHeight, root.allDayRows * (Constants.allDayEventHeight + Constants.eventBarSpacing) + Constants.spacingXs * 2)
        color: Constants.allDayBackground
        clip: true
        Text {
            width: root.gutter
            anchors.verticalCenter: parent.verticalCenter
            text: L.tr("All day", Qt.uiLanguage)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeCaption
            color: Constants.textSecondary
        }
        Item {
            anchors.left: parent.left
            anchors.leftMargin: root.gutter
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            clip: true
            Item {
                x: -timeline.contentX
                width: root.gridWidth
                height: parent.height
                Repeater {
                    model: 7
                    Item {
                        id: allDayColumn
                        required property int index
                        x: index * root.dayWidth
                        width: root.dayWidth
                        height: parent.height
                        Repeater {
                            model: Events.dayEvents(root.events, Dates.addDays(root.firstDay, allDayColumn.index), true)
                            WeekEventItem {
                                required property int index
                                required property var modelData
                                eventData: modelData
                                compact: true
                                x: Constants.spacing2xs
                                y: Constants.spacingXs + index * (Constants.allDayEventHeight + Constants.eventBarSpacing)
                                width: Math.max(0, allDayColumn.width - 2 * Constants.spacing2xs)
                                height: Constants.allDayEventHeight
                                onActivated: function (eventData) {
                                    root.eventSelected(eventData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    Item {
        id: timeGutter
        anchors.top: allDayHeader.bottom
        height: Math.max(0, root.height - y)
        anchors.left: parent.left
        width: root.gutter
        clip: true
        Item {
            y: -timeline.contentY
            width: parent.width
            height: timeline.contentHeight
            Repeater {
                model: 24
                Text {
                    required property int index
                    y: index * root.hourHeight + Constants.spacing2xs
                    width: parent.width - Constants.spacing2xs
                    text: (index < 10 ? "0" : "") + index + ":00"
                    color: Constants.textSecondary
                    font.family: Constants.fontFamily
                    font.pixelSize: Constants.fontSizeCaption
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
    Flickable {
        id: timeline
        anchors.top: allDayHeader.bottom
        height: Math.max(0, root.height - y)
        anchors.left: timeGutter.right
        anchors.right: parent.right
        contentWidth: root.gridWidth
        contentHeight: 24 * root.hourHeight
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.AutoFlickIfNeeded
        clip: true
        Component.onCompleted: Qt.callLater(root.focusSelectedDay)
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        ScrollBar.horizontal: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        // Horizontal row lines are drawn once, not once per day.
        Repeater {
            model: 24
            Rectangle {
                required property int index
                y: index * root.hourHeight
                width: root.gridWidth
                height: root.hourHeight
                color: index >= 8 && index < 18 ? Constants.timelineWorkingHoursBackground : Constants.timelineNonWorkingHoursBackground
                Rectangle {
                    width: parent.width
                    height: Constants.borderWidth
                    color: Constants.timelineHourLine
                }
                Rectangle {
                    y: parent.height / 2
                    width: parent.width
                    height: Constants.borderWidth
                    color: Constants.timelineHalfHourLine
                }
            }
        }
        Repeater {
            model: 7
            Item {
                id: dayColumn
                required property int index
                readonly property var dayDate: Dates.addDays(root.firstDay, index)
                x: index * root.dayWidth
                width: root.dayWidth
                height: timeline.contentHeight
                Rectangle {
                    width: Constants.borderWidth
                    height: parent.height
                    color: Constants.calendarGridLine
                }
                Item {
                    anchors.fill: parent
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onDoubleTapped: function (point, button) {
                            root.createRequested(dayColumn.dayDate, Math.max(0, Math.min(1410, Math.floor(point.position.y / root.hourHeight * 2) * 30)));
                        }
                    }
                }
                Repeater {
                    model: Events.lanes(root.events, dayColumn.dayDate)
                    WeekEventItem {
                        required property var modelData
                        eventData: modelData.event
                        x: modelData.lane * dayColumn.width / modelData.laneCount + Constants.spacing2xs
                        y: eventData.startMinute / 60 * root.hourHeight
                        width: Math.max(0, dayColumn.width / modelData.laneCount - 2 * Constants.spacing2xs)
                        height: Math.max(1, (eventData.endMinute - eventData.startMinute) / 60 * root.hourHeight - Constants.eventBarSpacing)
                        onActivated: function (eventData) {
                            root.eventSelected(eventData);
                        }
                    }
                }
                Rectangle {
                    visible: Dates.sameDate(dayColumn.dayDate, root.clock)
                    y: (root.clock.getHours() + root.clock.getMinutes() / 60) * root.hourHeight
                    width: parent.width
                    height: Constants.timelineNowLineWidth
                    color: Constants.timelineNowLine
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: Constants.timelineNowDotSize
                        height: width
                        radius: width / 2
                        color: Constants.timelineNowDot
                    }
                }
            }
        }
    }
    function focusSelectedDay() {
        timeline.contentY = Math.max(0, Math.min(8 * hourHeight, timeline.contentHeight - timeline.height));
        timeline.contentX = Math.max(0, Math.min(((selectedDate.getDay() - root.firstWeekday + 7) % 7) * dayWidth - timeline.width / 2 + dayWidth / 2, timeline.contentWidth - timeline.width));
    }
    onFirstDayChanged: Qt.callLater(focusSelectedDay)
}
