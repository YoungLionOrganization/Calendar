// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar
import "../Components" as Components
import "../Shared/EventData.mjs" as Events
import "../Shared/I18n.js" as L

Rectangle {
    id: root
    property var selectedDate: new Date()
    property var events: []
    readonly property var items: Events.dayEvents(events, selectedDate, true).concat(Events.dayEvents(events, selectedDate, false))
    signal eventSelected(var eventData)
    signal addRequested
    color: Constants.surfaceSecondary
    radius: Constants.radiusCard
    border.width: Constants.borderWidth
    border.color: Constants.borderSubtle
    clip: true
    Item {
        id: bar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Constants.spacingXs
        height: Constants.controlHeightMd
        Text {
            anchors.left: parent.left
            anchors.right: add.left
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.locale(Qt.uiLanguage).toString(root.selectedDate, "d MMMM yyyy")
            color: Constants.textPrimary
            font.pixelSize: Constants.fontSizeSectionTitle
            font.weight: Constants.fontWeightSemibold
            elide: Text.ElideRight
        }
        Components.CalendarToolButton {
            id: add
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: "+"
            hint: L.tr("New event", Qt.uiLanguage)
            onClicked: root.addRequested()
        }
    }
    ListView {
        id: list
        anchors.top: bar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Constants.spacingXs
        clip: true
        model: root.items
        spacing: Constants.spacingXs
        delegate: AgendaEventItem {
            required property var modelData
            width: list.width
            height: Constants.controlHeightLg
            eventData: modelData
            onActivated: function (e) {
                root.eventSelected(e);
            }
        }
    }
    Text {
        anchors.centerIn: list
        visible: list.count === 0
        width: list.width
        text: L.tr("No events for this day", Qt.uiLanguage)
        color: Constants.textSecondary
        font.pixelSize: Constants.fontSizeCaption
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
