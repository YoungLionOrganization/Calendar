// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar
import "../Components" as Components
import "../Shared/I18n.js" as L

Item {
    id: root
    property string titleText: ""
    property bool largeTitle: false
    property bool previousEnabled: true
    property bool nextEnabled: true
    signal previousRequested
    signal nextRequested
    height: Constants.monthHeaderHeight
    Label {
        anchors.left: parent.left
        anchors.right: buttons.left
        anchors.rightMargin: Constants.spacingXs
        anchors.verticalCenter: parent.verticalCenter
        text: root.titleText
        color: Constants.textPrimary
        font.family: Constants.fontFamily
        font.weight: Constants.fontWeightBold
        font.pixelSize: root.largeTitle ? Constants.fontSize4xl : Constants.fontSizeMonthTitle
        elide: Text.ElideRight
    }
    Row {
        id: buttons
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Constants.spacingXs
        Components.CalendarToolButton {
            icon.source: "../../assets/svg/arrow_left.svg"
            hint: L.tr("Previous", Qt.uiLanguage)
            enabled: root.previousEnabled
            onClicked: root.previousRequested()
        }
        Components.CalendarToolButton {
            icon.source: "../../assets/svg/arrow_right.svg"
            hint: L.tr("Next", Qt.uiLanguage)
            enabled: root.nextEnabled
            onClicked: root.nextRequested()
        }
    }
}
