// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import Calendar
import "../Shared/EventData.mjs" as Events

Rectangle {
    id: root
    required property var eventData
    property bool compact: false
    signal activated(var eventData)
    color: eventData.background
    radius: Constants.radiusEvent
    clip: true
    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Constants.eventAccentBarWidth
        color: root.eventData.color
    }
    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Constants.eventAccentBarWidth + Constants.spacing2xs
        anchors.rightMargin: Constants.spacing2xs
        anchors.topMargin: Constants.spacing2xs
        text: root.eventData.title
        textFormat: Text.PlainText
        color: Constants.eventText
        font.family: Constants.fontFamily
        font.pixelSize: Constants.fontSizeEventTitle
        font.weight: Constants.fontWeightMedium
        elide: Text.ElideRight
        maximumLineCount: 1
    }
    Text {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Constants.eventAccentBarWidth + Constants.spacing2xs
        anchors.rightMargin: Constants.spacing2xs
        anchors.bottomMargin: Constants.spacing2xs
        visible: !root.compact && !root.eventData.allDay && root.height >= Constants.fontSizeEventTitle + Constants.fontSizeEventTime + 3 * Constants.spacing2xs
        text: Events.timeText(root.eventData.date, root.eventData.startMinute, Qt.locale(Qt.uiLanguage), Constants.use24HourClock)
        color: Constants.eventSecondaryText
        font.family: Constants.fontFamily
        font.pixelSize: Constants.fontSizeEventTime
        elide: Text.ElideRight
    }
    TapHandler {
        onTapped: root.activated(root.eventData)
    }
}
