// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar

ApplicationWindow {
    id: appWindow
    property var calendarWorker: null
    property var backend: null
    property var platform: null
    property string startupTarget: ""

    function activate(target) {
        if (target.startsWith("event:"))
            calendar.openDetails(target.slice(6));
        else if (target && backend)
            calendar.previewFile(target);
        show();
        raise();
        requestActivate();
    }

    Component.onCompleted: {
        if (startupTarget)
            Qt.callLater(() => activate(startupTarget));
    }
    Connections {
        target: appWindow.platform
        function onOpenRequested(target) { appWindow.activate(target); }
    }

    // Initial window geometry only; never bound to the page.
    width: Constants.preferredDesktopWidth
    height: Constants.preferredDesktopHeight
    visible: true
    title: Constants.appName
    color: Constants.background
    palette.window: Constants.background
    palette.windowText: Constants.textPrimary
    palette.base: Constants.surface
    palette.text: Constants.textPrimary
    palette.button: Constants.surfaceSecondary
    palette.buttonText: Constants.textPrimary
    palette.highlight: Constants.primary
    palette.highlightedText: Constants.textOnPrimary

    Main {
        id: calendar
        platform: appWindow.platform
        backend: appWindow.backend
        calendarWorker: appWindow.calendarWorker
        anchors.fill: parent
    }
}
