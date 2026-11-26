// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

SpinBox {
    id: control

    hoverEnabled: true
    padding: 0
    implicitWidth: 104
    implicitHeight: Constants.inputHeight
    font.family: Constants.fontFamily
    font.pixelSize: Constants.fontSizeInput
    palette.text: enabled ? Constants.textPrimary : Constants.textDisabled
    palette.highlight: Constants.inputSelectionBackground
    palette.highlightedText: Constants.inputSelectionText

    background: ControlSurface {
        target: control
        hovered: control.hovered
        implicitHeight: Constants.inputHeight
        implicitWidth: 104
    }

    up.indicator: StepIndicator {
        x: control.mirrored ? 4 : control.width - width - 4
        symbol: "+"
        pressed: control.up.pressed
        hovered: control.up.hovered
    }

    down.indicator: StepIndicator {
        x: control.mirrored ? control.width - width - 4 : 4
        symbol: "−"
        pressed: control.down.pressed
        hovered: control.down.hovered
    }

    leftPadding: (mirrored ? up.indicator.width : down.indicator.width) + 4
    rightPadding: (mirrored ? down.indicator.width : up.indicator.width) + 4

    component StepIndicator: Rectangle {
        id: step
        required property string symbol
        required property bool pressed
        required property bool hovered

        y: 4
        width: Math.min(Constants.touchMode ? 36 : 28, control.width * 0.22)
        height: Math.max(0, control.height - 8)
        radius: Constants.radiusSm
        color: !enabled ? "transparent" : pressed ? Constants.surfacePressed : hovered ? Constants.surfaceHover : Constants.surfaceSecondary

        Text {
            anchors.centerIn: parent
            text: step.symbol
            color: step.enabled ? Constants.textPrimary : Constants.textDisabled
            font.family: Constants.fontFamily
            font.pixelSize: Constants.fontSizeInput
        }
    }
}
