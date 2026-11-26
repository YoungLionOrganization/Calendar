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
    property int rangeDays: 14
    readonly property var rows: Events.agendaRows(events, selectedDate, rangeDays)
    signal previousRequested
    signal nextRequested
    signal eventSelected(var eventData)

    PeriodNavigation {
        id: navigation
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        titleText: L.tr("Agenda", Qt.uiLanguage)
        previousEnabled: Dates.addDays(root.selectedDate, -root.rangeDays).getFullYear() >= 1900
        nextEnabled: Dates.addDays(root.selectedDate, root.rangeDays).getFullYear() <= 2100
        onPreviousRequested: root.previousRequested()
        onNextRequested: root.nextRequested()
    }
    Text {
        id: rangeLabel
        anchors.top: navigation.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        text: Qt.locale(Qt.uiLanguage).toString(root.selectedDate, "d MMM yyyy") + " – " + Qt.locale(Qt.uiLanguage).toString(Dates.addDays(root.selectedDate, root.rangeDays - 1), "d MMM yyyy")
        color: Constants.textSecondary
        font.family: Constants.fontFamily
        font.pixelSize: Constants.fontSizeCaption
        elide: Text.ElideRight
    }
    ListView {
        id: agendaList
        anchors.top: rangeLabel.bottom
        anchors.topMargin: Constants.spacingMd
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(0, root.height - y)
        clip: true
        spacing: Constants.spacingXs
        boundsBehavior: Flickable.StopAtBounds
        model: root.rows
        reuseItems: true
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        delegate: Item {
            id: row
            required property var modelData
            width: agendaList.width
            height: modelData.kind === "day" ? Constants.controlHeightMd : Constants.controlHeightLg + Constants.spacingMd
            Loader {
                anchors.fill: parent
                sourceComponent: row.modelData.kind === "day" ? dayComponent : eventComponent
            }
            Component {
                id: dayComponent
                Item {
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: Dates.sameDate(row.modelData.date, root.referenceDate) ? L.tr("Today", Qt.uiLanguage) + " · " + Qt.locale(Qt.uiLanguage).toString(row.modelData.date, "d MMM") : Qt.locale(Qt.uiLanguage).toString(row.modelData.date, "dddd, d MMMM")
                        color: Dates.sameDate(row.modelData.date, root.referenceDate) ? Constants.primary : Constants.textPrimary
                        font.family: Constants.fontFamily
                        font.pixelSize: Constants.fontSizeSectionTitle
                        font.weight: Constants.fontWeightSemibold
                        width: parent.width
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Constants.borderWidth
                        color: Constants.divider
                    }
                }
            }
            Component {
                id: eventComponent
                AgendaEventItem {
                    eventData: row.modelData.event
                    onActivated: function (eventData) {
                        root.eventSelected(eventData);
                    }
                }
            }
        }
        onModelChanged: positionViewAtBeginning()
    }
    Column {
        anchors.centerIn: agendaList
        width: agendaList.width
        spacing: Constants.spacingSm
        visible: root.rows.length === 0
        Text {
            width: parent.width
            text: L.tr("No upcoming events", Qt.uiLanguage)
            horizontalAlignment: Text.AlignHCenter
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeMd
            font.weight: Constants.fontWeightSemibold
            color: Constants.textPrimary
        }
        Text {
            width: parent.width
            text: L.tr("There are no events in this date range.", Qt.uiLanguage)
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeCaption
            color: Constants.textSecondary
        }
    }
}
