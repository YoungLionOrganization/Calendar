// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

MenuItem {
    id: control

    hoverEnabled: true
    font.family: Constants.fontFamily
    font.pixelSize: Constants.fontSizeButton
    icon.color: enabled ? Constants.textPrimary : Constants.textDisabled
    palette.windowText: enabled ? Constants.textPrimary : Constants.textDisabled

    background: Rectangle {
        implicitHeight: Constants.menuItemHeight
        radius: Constants.radiusSm
        color: control.down ? Constants.surfacePressed : control.highlighted ? Constants.surfaceHover : "transparent"
    }
}
