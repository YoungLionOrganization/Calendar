// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import Calendar
import "../Shared/EventData.mjs" as Events
import "../Shared/I18n.js" as L

Rectangle {
    id: root
    required property var eventData
    signal activated(var eventData)
    color: tap.pressed ? Constants.surfacePressed : Constants.surfaceSecondary
    radius: Constants.radiusEvent
    clip: true
    Rectangle {
        id: accent
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: Constants.spacingXs
        width: Constants.eventAccentBarWidth
        radius: width / 2
        color: root.eventData.color
    }
    Column {
        anchors.left: accent.right
        anchors.leftMargin: Constants.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(Constants.timelineTimeColumnWidth + Constants.spacingLg, root.width / 3)
        spacing: Constants.spacing2xs
        Text {
            width: parent.width
            text: root.eventData.allDay ? L.tr("All day", Qt.uiLanguage) : Events.timeText(root.eventData.date, root.eventData.startMinute, Qt.locale(Qt.uiLanguage), Constants.use24HourClock)
            color: Constants.textPrimary
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeSm
            font.weight: Constants.fontWeightMedium
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: !root.eventData.allDay
            text: Events.timeText(root.eventData.date, root.eventData.endMinute, Qt.locale(Qt.uiLanguage), Constants.use24HourClock)
            color: Constants.textSecondary
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeCaption
            elide: Text.ElideRight
        }
    }
    Column {
        anchors.left: parent.left
        anchors.leftMargin: Constants.spacingXs + Constants.eventAccentBarWidth + Constants.spacingSm + Math.min(Constants.timelineTimeColumnWidth + Constants.spacingLg, root.width / 3) + Constants.spacingSm
        anchors.right: parent.right
        anchors.rightMargin: Constants.spacingSm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Constants.spacing2xs
        Text {
            width: parent.width
            text: root.eventData.title
            textFormat: Text.PlainText
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeBody
            font.weight: Constants.fontWeightSemibold
            color: Constants.textPrimary
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: root.eventData.location || ""
            textFormat: Text.PlainText
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeCaption
            color: Constants.textSecondary
            elide: Text.ElideRight
        }
    }
    TapHandler {
        id: tap
        onTapped: root.activated(root.eventData)
    }
}
