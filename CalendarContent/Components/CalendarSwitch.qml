// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Switch {
    id: control

    hoverEnabled: true
    spacing: Constants.spacingSm
    font.family: Constants.fontFamily
    font.pixelSize: Constants.fontSizeInput
    palette.windowText: enabled ? Constants.textPrimary : Constants.textDisabled
    palette.buttonText: enabled ? Constants.textPrimary : Constants.textDisabled

    indicator: Rectangle {
        x: control.mirrored ? control.width - control.rightPadding - width : control.leftPadding
        y: (control.height - height) / 2
        implicitWidth: Constants.touchMode ? 48 : 42
        implicitHeight: Constants.touchMode ? 28 : 24
        radius: height / 2
        color: !control.enabled ? Constants.surfaceDisabled : control.checked ? Constants.primary : control.hovered ? Constants.surfaceHover : Constants.surfaceSecondary
        border.width: control.visualFocus ? Constants.focusRingWidth : Constants.borderWidth
        border.color: control.visualFocus ? Constants.focusRing : Constants.border

        Rectangle {
            readonly property bool atEnd: control.checked !== control.mirrored
            width: parent.height - 8
            height: width
            radius: width / 2
            y: 4
            x: atEnd ? parent.width - width - 4 : 4
            color: !control.enabled ? Constants.textDisabled : control.checked ? Constants.textOnPrimary : Constants.textSecondary
        }
    }
}
