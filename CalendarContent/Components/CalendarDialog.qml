// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

Dialog {
    id: root
    property real dialogAvailableWidth: Constants.dialogPreferredWidth
    parent: Overlay.overlay
    anchors.centerIn: parent
    width: Math.max(1, Math.min(dialogAvailableWidth - 2 * Constants.spacingMd, Constants.dialogPreferredWidth))
    modal: true
    padding: Constants.spacingLg
    palette.window: Constants.surface
    palette.windowText: Constants.textPrimary
    palette.base: Constants.inputBackground
    palette.text: Constants.textPrimary
    palette.button: Constants.surfaceSecondary
    palette.buttonText: Constants.textPrimary
    palette.highlight: Constants.primary
    palette.highlightedText: Constants.isDark ? Constants.navy950 : Constants.textOnPrimary
    background: Rectangle {
        color: Constants.dialogBackground
        radius: Constants.radiusDialog
        border.width: Constants.borderWidth
        border.color: Constants.border
    }
}
