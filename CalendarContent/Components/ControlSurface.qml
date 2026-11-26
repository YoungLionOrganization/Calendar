// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import Calendar

Rectangle {
    required property Item target
    property bool hovered: false
    property bool focused: target.activeFocus
    property color fill: Constants.inputBackground

    radius: Constants.radiusMd
    color: target.enabled ? fill : Constants.surfaceDisabled
    border.width: focused ? Constants.focusRingWidth : Constants.borderWidth
    border.color: focused ? Constants.focusRing : hovered ? Constants.inputHoverBorder : Constants.inputBorder
}
