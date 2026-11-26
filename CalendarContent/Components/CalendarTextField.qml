// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

TextField {
    id: control

    hoverEnabled: true
    padding: Constants.spacingSm
    font.family: Constants.fontFamily
    font.pixelSize: Constants.fontSizeInput
    color: enabled ? Constants.textPrimary : Constants.textDisabled
    placeholderTextColor: Constants.textPlaceholder
    selectionColor: Constants.inputSelectionBackground
    selectedTextColor: Constants.inputSelectionText

    background: ControlSurface {
        target: control
        hovered: control.hovered
        implicitHeight: Constants.textFieldMinHeight
        implicitWidth: 96
    }
}
