// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Item {
    id: root
    property string titleText: ""
    property string dateText: ""
    height: Constants.topBarHeight
    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Constants.spacing2xs
        Label {
            width: parent.width
            text: root.titleText
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeAppTitle
            font.weight: Constants.fontWeightBold
            color: Constants.textPrimary
            elide: Text.ElideRight
        }
        Label {
            width: parent.width
            text: root.dateText
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeTiny
            font.weight: Constants.fontWeightMedium
            color: Constants.textSecondary
            elide: Text.ElideRight
        }
    }
}
