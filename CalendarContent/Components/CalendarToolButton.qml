// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

ToolButton {
    id: control
    property bool active: false
    property string hint: ""
    implicitWidth: Constants.iconButtonSize
    implicitHeight: Constants.iconButtonSize
    icon.width: Constants.iconSizeMd
    icon.height: Constants.iconSizeMd
    icon.color: active ? Constants.primary : Constants.textPrimary
    font.family: Constants.fontFamily
    font.pixelSize: Constants.fontSizeButton
    palette.buttonText: !enabled ? Constants.textDisabled : active ? Constants.primary : Constants.textPrimary
    hoverEnabled: true
    ToolTip.text: hint
    ToolTip.visible: hovered && hint.length > 0
    Accessible.name: hint.length > 0 ? hint : text
    background: Rectangle {
        radius: Constants.radiusMd
        color: control.down ? Constants.surfacePressed : control.hovered ? Constants.surfaceHover : control.active ? Constants.primarySubtle : "transparent"
        border.width: control.activeFocus ? Constants.focusRingWidth : 0
        border.color: Constants.focusRing
    }
}
