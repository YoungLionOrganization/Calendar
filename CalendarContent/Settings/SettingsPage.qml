// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calendar
import "../Components" as Common
import "../Shared/I18n.js" as L

Common.PageShell {
    id: root
    required property var preferences
    property bool canUseFiles: false
    property var backend: null
    property var platform: null
    signal importRequested
    signal exportRequested
    signal samplesRequested
    titleText: L.tr("Settings", Qt.uiLanguage)
    Flickable {
        id: scroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: form.height + 2 * Constants.pagePadding
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
        }
        ColumnLayout {
            id: form
            width: Math.max(0, Math.min(scroll.width - 2 * Constants.pagePadding, Constants.settingsMaxWidth))
            x: (scroll.width - width) / 2
            y: Constants.pagePadding
            spacing: Constants.spacingMd
            Common.SectionLabel {
                text: L.tr("Appearance", Qt.uiLanguage)
            }
            Label {
                text: L.tr("Theme", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                model: [L.tr("System", Qt.uiLanguage), L.tr("Light", Qt.uiLanguage), L.tr("Dark", Qt.uiLanguage)]
                currentIndex: ["system", "light", "dark"].indexOf(Constants.themeMode)
                onActivated: function (i) {
                    Constants.themeMode = ["system", "light", "dark"][i];
                }
            }
            Common.CalendarSwitch {
                text: L.tr("High contrast", Qt.uiLanguage)
                checked: Constants.highContrast
                onToggled: Constants.highContrast = checked
            }
            Common.CalendarSwitch {
                text: L.tr("Compact layout", Qt.uiLanguage)
                checked: Constants.compactDensity
                onToggled: Constants.compactDensity = checked
            }
            Common.CalendarSwitch {
                text: L.tr("Touch layout", Qt.uiLanguage)
                checked: Constants.touchMode
                onToggled: Constants.touchMode = checked
            }
            Label {
                text: L.tr("Text scale", Qt.uiLanguage) + " · " + Math.round(Constants.uiScale * 100) + "%"
                color: Constants.textSecondary
            }
            Slider {
                Layout.fillWidth: true
                from: 0.85
                to: 1.5
                stepSize: 0.05
                value: Constants.uiScale
                onMoved: Constants.uiScale = value
            }
            Common.SectionLabel {
                text: L.tr("Calendar preferences", Qt.uiLanguage)
            }
            Label {
                text: L.tr("Default view", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                model: [L.tr("Year", Qt.uiLanguage), L.tr("Month", Qt.uiLanguage), L.tr("Week", Qt.uiLanguage), L.tr("Agenda", Qt.uiLanguage)]
                currentIndex: ["year", "month", "week", "agenda"].indexOf(root.preferences.defaultView)
                onActivated: function (i) {
                    root.preferences.setDefaultView(["year", "month", "week", "agenda"][i]);
                }
            }
            Common.CalendarTextField {
                visible: !!root.backend
                Layout.fillWidth: true
                text: root.preferences.displayZone
                placeholderText: L.tr("Time zone, for example Asia/Baku", Qt.uiLanguage)
                Accessible.name: placeholderText
                onEditingFinished: {
                    if (root.backend.isTimeZone(text.trim()))
                        root.preferences.displayZone = text.trim();
                    else
                        text = root.preferences.displayZone;
                }
            }
            Common.CalendarSwitch {
                text: L.tr("24-hour time", Qt.uiLanguage)
                checked: root.preferences.use24HourClock
                onToggled: root.preferences.use24HourClock = checked
            }
            Label {
                text: L.tr("Accent color", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                model: [L.tr("Blue", Qt.uiLanguage), L.tr("Green", Qt.uiLanguage), L.tr("Violet", Qt.uiLanguage)]
                currentIndex: ["blue", "green", "violet"].indexOf(root.preferences.accent)
                onActivated: index => root.preferences.accent = ["blue", "green", "violet"][index]
            }
            Common.SectionLabel { text: L.tr("Local calendars", Qt.uiLanguage) }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                readonly property var keys: ["", "local", ...root.preferences.localCalendars.map(calendar => calendar.id)]
                model: [L.tr("Show all calendars", Qt.uiLanguage), L.tr("Local calendar", Qt.uiLanguage),
                        ...root.preferences.localCalendars.map(calendar => calendar.title)]
                currentIndex: Math.max(0, keys.indexOf(root.preferences.calendarFilter))
                onActivated: index => root.preferences.calendarFilter = keys[index]
            }
            Common.CalendarTextField {
                id: calendarName
                Layout.fillWidth: true
                placeholderText: L.tr("New calendar name", Qt.uiLanguage)
                Accessible.name: placeholderText
            }
            Common.CalendarComboBox {
                id: newCalendarColor
                Layout.fillWidth: true
                model: [L.tr("Blue", Qt.uiLanguage), L.tr("Green", Qt.uiLanguage), L.tr("Violet", Qt.uiLanguage)]
                Accessible.name: L.tr("Calendar color", Qt.uiLanguage)
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                text: L.tr("Create calendar", Qt.uiLanguage)
                enabled: calendarName.text.trim().length > 0
                         && !root.preferences.localCalendars.some(calendar => calendar.title === calendarName.text.trim())
                onClicked: {
                    if (root.preferences.addCalendar(calendarName.text, ["#638bfa", "#15966e", "#a790f1"][newCalendarColor.currentIndex]))
                        calendarName.clear();
                }
            }
            Label {
                text: L.tr("First day of week", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                model: [0, 1, 2, 3, 4, 5, 6].map(day => Qt.locale(Qt.uiLanguage).dayName(day, Locale.LongFormat))
                currentIndex: root.preferences.firstWeekday
                onActivated: index => root.preferences.firstWeekday = index
            }
            Label {
                text: L.tr("Non-working days", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Flow {
                Layout.fillWidth: true
                Layout.preferredHeight: childrenRect.height
                spacing: Constants.spacingXs
                Repeater {
                    model: 7
                    Common.CalendarButton {
                        required property int index
                        text: Qt.locale(Qt.uiLanguage).dayName(index, Locale.ShortFormat)
                        checkable: true
                        highlighted: (root.preferences.nonWorkingDays & (1 << index)) !== 0
                        checked: highlighted
                        onClicked: root.preferences.nonWorkingDays ^= 1 << index
                    }
                }
            }
            Label {
                text: L.tr("Default event duration", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarSpinBox {
                Layout.fillWidth: true
                from: 15
                to: 180
                stepSize: 15
                value: root.preferences.defaultDuration
                onValueModified: root.preferences.defaultDuration = value
            }
            Label {
                text: L.tr("Default reminder", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                readonly property var values: [-1, 5, 15, 30, 60]
                model: [L.tr("No reminder", Qt.uiLanguage), L.tr("5 minutes before", Qt.uiLanguage),
                        L.tr("15 minutes before", Qt.uiLanguage), L.tr("30 minutes before", Qt.uiLanguage),
                        L.tr("1 hour before", Qt.uiLanguage)]
                currentIndex: Math.max(0, values.indexOf(root.preferences.defaultReminder))
                onActivated: index => root.preferences.defaultReminder = values[index]
            }
            Label {
                text: L.tr("Agenda range", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                model: [L.tr("7 days", Qt.uiLanguage), L.tr("14 days", Qt.uiLanguage), L.tr("30 days", Qt.uiLanguage)]
                currentIndex: [7, 14, 30].indexOf(root.preferences.agendaDays)
                onActivated: function (i) {
                    root.preferences.setAgendaDays([7, 14, 30][i]);
                }
            }
            Common.CalendarSwitch {
                text: L.tr("Show important days tab", Qt.uiLanguage)
                checked: root.preferences.showImportantTab
                onToggled: root.preferences.setImportantTab(checked)
            }
            Common.CalendarSwitch {
                text: L.tr("Show event markers", Qt.uiLanguage)
                checked: root.preferences.showEventMarkers
                onToggled: root.preferences.setEventMarkers(checked)
            }
            Common.SectionLabel {
                text: L.tr("Language and region", Qt.uiLanguage)
            }
            Common.CalendarComboBox {
                Layout.fillWidth: true
                model: [L.tr("System", Qt.uiLanguage), "English", "Türkçe", "Azərbaycanca"]
                currentIndex: ["system", "en_US", "tr_TR", "az_AZ"].indexOf(root.preferences.language)
                onActivated: function (i) {
                    root.preferences.setLanguage(["system", "en_US", "tr_TR", "az_AZ"][i]);
                }
            }
            Label {
                Layout.fillWidth: true
                text: L.tr("Dates and month names follow the selected language.", Qt.uiLanguage)
                color: Constants.textSecondary
                wrapMode: Text.WordWrap
            }
            Common.SectionLabel {
                text: L.tr("Performance", Qt.uiLanguage)
            }
            Common.CalendarSwitch {
                text: L.tr("Reduce motion", Qt.uiLanguage)
                checked: Constants.reduceMotion
                onToggled: Constants.reduceMotion = checked
            }
            Common.CalendarSwitch {
                text: L.tr("Low power mode", Qt.uiLanguage)
                checked: Constants.lowPowerMode
                onToggled: Constants.lowPowerMode = checked
            }
            Common.SectionLabel {
                text: L.tr("Local data", Qt.uiLanguage)
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                visible: root.canUseFiles
                text: L.tr("Import calendar", Qt.uiLanguage)
                onClicked: root.importRequested()
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                visible: root.canUseFiles
                text: L.tr("Export calendar", Qt.uiLanguage)
                onClicked: root.exportRequested()
            }
            Common.SectionLabel {
                visible: !!root.platform && root.platform.canLinkCalendars
                text: L.tr("System calendars", Qt.uiLanguage)
            }
            Common.CalendarButton {
                visible: !!root.platform && root.platform.canLinkCalendars
                text: L.tr("Allow access to system calendars", Qt.uiLanguage)
                onClicked: root.platform.authorizeSystemCalendars()
            }
            Common.CalendarComboBox {
                visible: !!root.platform && root.platform.canLinkCalendars
                Layout.fillWidth: true
                readonly property var calendars: root.platform ? root.platform.systemCalendars : []
                readonly property var keys: ["", ...calendars.map(calendar => calendar.id)]
                model: [L.tr("Disconnected", Qt.uiLanguage), ...calendars.map(calendar => calendar.title)]
                currentIndex: root.platform ? Math.max(0, keys.indexOf(root.platform.selectedSystemCalendar)) : 0
                onActivated: index => root.platform.selectedSystemCalendar = keys[index]
            }
            Common.CalendarButton {
                visible: !!root.platform && root.platform.canSetDefault
                text: L.tr("Set as default for calendar files", Qt.uiLanguage)
                onClicked: {
                    if (root.platform.setAsDefault())
                        defaultStatus.text = L.tr("Default calendar file app updated", Qt.uiLanguage);
                    else
                        defaultStatus.text = L.tr("Could not set the default calendar app", Qt.uiLanguage);
                }
            }
            Label { id: defaultStatus; visible: text.length > 0; color: Constants.textSecondary }
            Common.CalendarButton {
                visible: !!root.platform && Qt.platform.os === "android"
                text: L.tr("Allow exact reminders", Qt.uiLanguage)
                onClicked: root.platform.allowExactReminders()
            }
            Common.CalendarSwitch {
                visible: !!root.platform && root.platform.backgroundAvailable
                text: L.tr("Remind me when the window is closed", Qt.uiLanguage)
                checked: root.platform ? root.platform.backgroundEnabled : false
                onToggled: {
                    if (!root.platform.allowBackground(checked))
                        checked = root.platform.backgroundEnabled;
                }
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                text: L.tr("Add sample events", Qt.uiLanguage)
                onClicked: root.samplesRequested()
            }
            Label {
                Layout.fillWidth: true
                text: L.tr("Events and preferences are saved on this device.", Qt.uiLanguage)
                color: Constants.textSecondary
                wrapMode: Text.WordWrap
            }
            Common.CalendarButton {
                Layout.fillWidth: true
                text: L.tr("Reset preferences", Qt.uiLanguage)
                onClicked: resetDialog.open()
            }
            Common.SectionLabel {
                text: L.tr("About", Qt.uiLanguage)
            }
            Label {
                text: Constants.appName + " · " + Constants.appVersion
                color: Constants.textSecondary
            }
        }
    }
    Common.CalendarDialog {
        id: resetDialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        title: L.tr("Reset preferences?", Qt.uiLanguage)
        width: Math.max(1, Math.min(root.width - 2 * Constants.spacingSm, Constants.dialogPreferredWidth))
        contentItem: Label {
            text: L.tr("Your events will not be deleted.", Qt.uiLanguage)
            wrapMode: Text.WordWrap
            color: Constants.textPrimary
        }
        footer: DialogButtonBox {
            Common.CalendarButton {
                text: L.tr("Cancel", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
            Common.CalendarButton {
                text: L.tr("Reset", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
        onAccepted: root.preferences.reset()
    }
}
