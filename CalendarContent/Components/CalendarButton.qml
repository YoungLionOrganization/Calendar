// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Button {
    id: control
    property bool destructive: false

    hoverEnabled: true
    leftPadding: Constants.spacingMd
    rightPadding: Constants.spacingMd
    font.family: Constants.fontFamily
    font.pixelSize: Constants.fontSizeButton
    font.weight: Constants.fontWeightSemibold
    palette.buttonText: !enabled ? Constants.textDisabled : destructive ? Constants.error : Constants.textPrimary
    palette.brightText: !enabled ? Constants.textDisabled : Constants.isDark && !down ? Constants.navy950 : Constants.textOnPrimary

    background: ControlSurface {
        target: control
        focused: control.visualFocus
        hovered: control.hovered
        implicitHeight: Constants.buttonHeight
        fill: control.highlighted ? (control.down ? Constants.primaryPressed : control.hovered ? Constants.primaryHover : Constants.primary) : (control.down ? Constants.surfacePressed : control.hovered ? Constants.surfaceHover : Constants.surfaceSecondary)
    }
}
