// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Menu {
    padding: Constants.spacingXs
    palette.text: Constants.textPrimary
    palette.windowText: Constants.textPrimary
    palette.highlight: Constants.primary
    palette.highlightedText: Constants.textOnPrimary
    palette.mid: Constants.border

    delegate: CalendarMenuItem {}

    background: Rectangle {
        implicitWidth: Constants.menuMinWidth
        radius: Constants.radiusMd
        color: Constants.popupBackground
        border.color: Constants.border
        border.width: Constants.borderWidth
    }
}
