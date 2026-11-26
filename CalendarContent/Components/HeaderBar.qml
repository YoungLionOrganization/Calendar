// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import Calendar
import "../Shared/I18n.js" as L

Item {
    id: root
    property bool modeOpen: false
    signal addRequested
    signal viewRequested
    signal searchRequested
    signal goRequested
    signal settingsRequested
    signal todayRequested
    height: Constants.topBarHeight

    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Constants.spacingXs
        CalendarToolButton {
            icon.source: "../../assets/svg/plus.svg"
            hint: L.tr("New event", Qt.uiLanguage)
            onClicked: root.addRequested()
        }
        CalendarToolButton {
            icon.source: "../../assets/svg/calendar.svg"
            hint: L.tr("Calendar view", Qt.uiLanguage)
            active: root.modeOpen
            onClicked: root.viewRequested()
        }
        CalendarToolButton {
            id: menuButton
            icon.source: "../../assets/svg/menu.svg"
            hint: L.tr("Menu", Qt.uiLanguage)
            onClicked: appMenu.open()
            CalendarMenu {
                id: appMenu
                y: menuButton.height
                x: menuButton.width - width
                width: Math.max(0, Math.min(Constants.popupPreferredWidth, root.width))
                CalendarMenuItem {
                    text: L.tr("New event", Qt.uiLanguage)
                    icon.source: "../../assets/svg/plus.svg"
                    onTriggered: root.addRequested()
                }
                CalendarMenuItem {
                    text: L.tr("Calendar view", Qt.uiLanguage)
                    icon.source: "../../assets/svg/calendar.svg"
                    onTriggered: root.viewRequested()
                }
                MenuSeparator {}
                CalendarMenu {
                    title: L.tr("Mode", Qt.uiLanguage)
                    CalendarMenuItem {
                        text: L.tr("System", Qt.uiLanguage)
                        checkable: true
                        checked: Constants.themeMode === "system"
                        onTriggered: Constants.themeMode = "system"
                    }
                    CalendarMenuItem {
                        text: L.tr("Light", Qt.uiLanguage)
                        checkable: true
                        checked: Constants.themeMode === "light"
                        onTriggered: Constants.themeMode = "light"
                    }
                    CalendarMenuItem {
                        text: L.tr("Dark", Qt.uiLanguage)
                        checkable: true
                        checked: Constants.themeMode === "dark"
                        onTriggered: Constants.themeMode = "dark"
                    }
                }
                CalendarMenuItem {
                    text: L.tr("Search", Qt.uiLanguage)
                    icon.source: "../../assets/svg/search.svg"
                    onTriggered: root.searchRequested()
                }
                CalendarMenuItem {
                    text: L.tr("Go to date", Qt.uiLanguage)
                    icon.source: "../../assets/svg/external_link.svg"
                    onTriggered: root.goRequested()
                }
                CalendarMenuItem {
                    text: L.tr("Today", Qt.uiLanguage)
                    icon.source: "../../assets/svg/calendar.svg"
                    onTriggered: root.todayRequested()
                }
                MenuSeparator {}
                CalendarMenuItem {
                    text: L.tr("Settings", Qt.uiLanguage)
                    icon.source: "../../assets/svg/settings.svg"
                    onTriggered: root.settingsRequested()
                }
            }
        }
    }
}
