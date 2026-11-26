// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

ComboBox {
    id: control

    hoverEnabled: true
    font.family: Constants.fontFamily
    font.pixelSize: Constants.fontSizeInput
    palette.button: Constants.popupBackground
    palette.buttonText: enabled ? Constants.textPrimary : Constants.textDisabled
    palette.base: Constants.popupBackground
    palette.text: Constants.textPrimary
    palette.window: Constants.popupBackground
    palette.windowText: Constants.textPrimary
    palette.highlight: Constants.primary
    palette.highlightedText: Constants.textPrimary
    palette.light: Constants.surfaceHover
    palette.midlight: Constants.surfacePressed
    palette.dark: Constants.textSecondary
    palette.mid: Constants.border

    background: ControlSurface {
        target: control
        hovered: control.hovered
        implicitHeight: Constants.inputHeight
        implicitWidth: 96
        fill: control.down ? Constants.surfacePressed : Constants.inputBackground
    }
}
