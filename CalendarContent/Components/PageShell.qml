// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calendar
import "../Shared/I18n.js" as L

Rectangle {
    id: root
    color: Constants.background
    property string titleText: ""
    property string subtitleText: ""
    property string actionText: ""
    property bool actionEnabled: true
    signal backRequested
    signal actionRequested
    default property alias pageContent: body.data
    Item {
        id: bar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(Constants.topBarHeight, Constants.controlHeightMd)
        RowLayout {
            anchors.fill: parent
            anchors.margins: Constants.spacingXs
            CalendarToolButton {
                text: "‹"
                font.pixelSize: Constants.fontSize2xl
                Accessible.name: L.tr("Back", Qt.uiLanguage)
                onClicked: root.backRequested()
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0
                Label {
                    Layout.fillWidth: true
                    text: root.titleText
                    font.family: Constants.fontFamily
                    font.pixelSize: Constants.fontSizeAppTitle
                    font.weight: Constants.fontWeightBold
                    color: Constants.textPrimary
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    visible: text.length > 0
                    text: root.subtitleText
                    color: Constants.textSecondary
                    font.pixelSize: Constants.fontSizeCaption
                    elide: Text.ElideRight
                }
            }
            CalendarButton {
                highlighted: true
                visible: root.actionText.length > 0
                text: root.actionText
                enabled: root.actionEnabled
                onClicked: root.actionRequested()
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: Constants.borderWidth
            color: Constants.divider
        }
    }
    Item {
        id: body
        anchors.top: bar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(0, root.height - y)
        clip: true
    }
}
