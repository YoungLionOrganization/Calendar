// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calendar
import "../Components" as Common
import "EventLogic.mjs" as Logic
import "../Shared/I18n.js" as L

Common.PageShell {
    id: root
    required property var record
    property var calendars: []
    readonly property var calendarIds: ["local", ...calendars.map(calendar => calendar.id)]
    signal saved(var record)
    property bool dirty: false
    property bool initialized: false
    readonly property var categoryKeys: Logic.categories()
    readonly property var repeatKeys: ["none", "daily", "weekly", "monthly", "yearly"]
    property var selectedWeekdays: []
    readonly property var reminderMinutes: reminderInput.text.trim() ? reminderInput.text.split(",").map(text => Number(text.trim())) : []
    readonly property bool remindersValid: /^\s*(\d{1,5}\s*(,\s*\d{1,5}\s*)*)?$/.test(reminderInput.text)
                                             && reminderMinutes.length <= 12 && reminderMinutes.every(value => value <= 10080)
    readonly property int startMinute: Logic.minute(startTime.text)
    readonly property int endMinute: Logic.minute(endTime.text)
    readonly property bool datesValid: endDate.dateKey >= startDate.dateKey && Logic.diff(Logic.date(endDate.dateKey), Logic.date(startDate.dateKey)) <= 365
    readonly property bool timesValid: allDay.checked || (startMinute >= 0 && startMinute < 1440 && endMinute > 0 && (endDate.dateKey !== startDate.dateKey || endMinute > startMinute))
    readonly property bool repeatValid: repeatBox.currentIndex === 0 || ((!untilSwitch.checked || untilDate.dateKey >= startDate.dateKey) && Logic.diff(Logic.date(endDate.dateKey), Logic.date(startDate.dateKey)) < [366, 1, 7, 28, 365][repeatBox.currentIndex])
    titleText: record.id ? L.tr("Edit event", Qt.uiLanguage) : L.tr("New event", Qt.uiLanguage)
    actionText: L.tr("Save", Qt.uiLanguage)
    readonly property bool providerEvent: String(record.id || "").startsWith("android:")
    readonly property bool unsupportedRule: !!record.rawRule && record.repeat === "none"
    actionEnabled: !unsupportedRule && initialized && titleInput.text.trim().length > 0 && datesValid && timesValid && repeatValid && remindersValid
    function changed() {
        if (initialized)
            dirty = true;
    }
    function requestBack() {
        if (dirty)
            discardDialog.open();
        else
            cancelRequested();
    }
    // Header back is intercepted by the parent via cancelRequested.
    signal cancelRequested
    onBackRequested: requestBack()
    onActionRequested: {
        const e = Object.assign({}, record, {
            title: titleInput.text.trim(),
            dateKey: startDate.dateKey,
            endDateKey: endDate.dateKey,
            startMinute: allDay.checked ? 0 : startMinute,
            endMinute: allDay.checked ? 1440 : endMinute,
            allDay: allDay.checked,
            category: categoryKeys[categoryBox.currentIndex],
            calendarId: calendarIds[calendarBox.currentIndex],
            location: locationInput.text.trim(),
            description: notesInput.text,
            important: importantSwitch.checked,
            timeZone: allDay.checked ? "" : zoneInput.text.trim(),
            reminders: [...new Set(reminderMinutes)],
            reminder: reminderMinutes.length ? reminderMinutes[0] : -1,
            weekdays: repeatBox.currentIndex === 2 ? selectedWeekdays : [],
            rawEvent: record.rawRule && record.repeat === "none" ? record.rawEvent : "",
            rawRule: record.rawRule && record.repeat === "none" ? record.rawRule : "",
            repeat: repeatKeys[repeatBox.currentIndex],
            repeatUntil: repeatBox.currentIndex > 0 && untilSwitch.checked ? untilDate.dateKey : ""
        });
        dirty = false;
        saved(e);
    }
    Component.onCompleted: {
        titleInput.text = record.title || "";
        startDate.setKey(record.dateKey);
        endDate.setKey(record.endDateKey || record.dateKey);
        allDay.checked = !!record.allDay;
        startTime.text = Logic.time(record.startMinute);
        endTime.text = Logic.time(record.endMinute);
        calendarBox.currentIndex = Math.max(0, calendarIds.indexOf(record.calendarId));
        categoryBox.currentIndex = Math.max(0, categoryKeys.indexOf(record.category));
        locationInput.text = record.location || "";
        notesInput.text = record.description || "";
        importantSwitch.checked = !!record.important;
        const reminders = record.reminders || (record.reminder >= 0 ? [record.reminder] : []);
        reminderInput.text = reminders.join(", ");
        zoneInput.text = record.timeZone || "";
        selectedWeekdays = record.weekdays || [];
        repeatBox.currentIndex = Math.max(0, repeatKeys.indexOf(record.repeat));
        untilSwitch.checked = !!record.repeatUntil;
        untilDate.setKey(record.repeatUntil || record.dateKey);
        initialized = true;
    }
    Common.CalendarDialog {
        id: discardDialog
        title: L.tr("Discard changes?", Qt.uiLanguage)
        width: Math.max(1, Math.min(root.width - 2 * Constants.spacingSm, Constants.dialogPreferredWidth))
        footer: DialogButtonBox {
            Common.CalendarButton {
                text: L.tr("Keep editing", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
            Common.CalendarButton {
                text: L.tr("Discard", Qt.uiLanguage)
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
        onAccepted: {
            root.dirty = false;
            root.cancelRequested();
        }
    }
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
            width: Math.max(0, Math.min(scroll.width - 2 * Constants.pagePadding, Constants.formMaxWidth))
            x: (scroll.width - width) / 2
            y: Constants.pagePadding
            spacing: Constants.formFieldSpacing
            Label {
                Layout.fillWidth: true
                visible: root.unsupportedRule
                text: L.tr("This file uses a recurrence rule that the editor cannot change.", Qt.uiLanguage)
                color: Constants.error
                wrapMode: Text.WordWrap
            }
            Common.SectionLabel {
                text: L.tr("Event details", Qt.uiLanguage)
                Layout.fillWidth: true
            }
            Common.CalendarTextField {
                id: titleInput
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                placeholderText: L.tr("Event title", Qt.uiLanguage)
                font.pixelSize: Constants.fontSizeInput
                onTextEdited: root.changed()
                Accessible.name: placeholderText
            }
            Label {
                text: L.tr("Category", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarComboBox {
                id: calendarBox
                visible: !root.providerEvent
                Layout.fillWidth: true
                model: [L.tr("Local calendar", Qt.uiLanguage), ...root.calendars.map(calendar => calendar.title)]
                Accessible.name: L.tr("Calendar", Qt.uiLanguage)
                onActivated: root.changed()
            }
            Common.CalendarComboBox {
                id: categoryBox
                Layout.fillWidth: true
                model: root.categoryKeys.map(function (c) {
                    return L.tr(Logic.categoryLabel(c), Qt.uiLanguage);
                })
                onActivated: root.changed()
            }
            Common.CalendarSwitch {
                id: importantSwitch
                text: L.tr("Mark as important", Qt.uiLanguage)
                onToggled: root.changed()
            }
            Common.SectionLabel {
                text: L.tr("Date and time", Qt.uiLanguage)
                Layout.fillWidth: true
            }
            Common.DateField {
                id: startDate
                Layout.fillWidth: true
                labelText: L.tr("Start date", Qt.uiLanguage)
                onDateKeyChanged: {
                    if (root.initialized && endDate.dateKey < dateKey)
                        endDate.setKey(dateKey);
                    root.changed();
                }
            }
            Common.DateField {
                id: endDate
                Layout.fillWidth: true
                labelText: L.tr("End date", Qt.uiLanguage)
                onDateKeyChanged: root.changed()
            }
            Common.CalendarSwitch {
                id: allDay
                text: L.tr("All day", Qt.uiLanguage)
                onToggled: root.changed()
            }
            RowLayout {
                visible: !allDay.checked
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        text: L.tr("Start time", Qt.uiLanguage)
                        color: Constants.textSecondary
                    }
                    Common.CalendarTextField {
                        id: startTime
                        Layout.fillWidth: true
                        placeholderText: "09:00"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        onTextEdited: root.changed()
                        Accessible.name: L.tr("Start time", Qt.uiLanguage)
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Label {
                        text: L.tr("End time", Qt.uiLanguage)
                        color: Constants.textSecondary
                    }
                    Common.CalendarTextField {
                        id: endTime
                        Layout.fillWidth: true
                        placeholderText: "10:00"
                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                        onTextEdited: root.changed()
                        Accessible.name: L.tr("End time", Qt.uiLanguage)
                    }
                }
            }
            Label {
                Layout.fillWidth: true
                visible: !root.datesValid || !root.timesValid
                text: L.tr("Check dates and times. Maximum duration: 366 days.", Qt.uiLanguage)
                color: Constants.error
                wrapMode: Text.WordWrap
            }
            Common.SectionLabel {
                text: L.tr("Repeat and reminder", Qt.uiLanguage)
                Layout.fillWidth: true
            }
            Common.CalendarComboBox {
                id: repeatBox
                visible: !root.providerEvent
                Layout.fillWidth: true
                model: [L.tr("Does not repeat", Qt.uiLanguage), L.tr("Daily", Qt.uiLanguage), L.tr("Weekly", Qt.uiLanguage), L.tr("Monthly", Qt.uiLanguage), L.tr("Yearly", Qt.uiLanguage)]
                onActivated: root.changed()
            }
            Common.CalendarSwitch {
                id: untilSwitch
                visible: repeatBox.currentIndex > 0
                text: L.tr("End repetition", Qt.uiLanguage)
                onToggled: root.changed()
            }
            Common.DateField {
                id: untilDate
                visible: repeatBox.currentIndex > 0 && untilSwitch.checked
                Layout.fillWidth: true
                labelText: L.tr("Repeat until", Qt.uiLanguage)
                onDateKeyChanged: root.changed()
            }
            Label {
                visible: !root.repeatValid
                Layout.fillWidth: true
                text: L.tr("Check repeat end and duration; occurrences must not overlap.", Qt.uiLanguage)
                color: Constants.error
                wrapMode: Text.WordWrap
            }
            Label {
                Layout.fillWidth: true
                visible: repeatBox.currentIndex === 2
                text: L.tr("Repeat on", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Flow {
                Layout.fillWidth: true
                visible: repeatBox.currentIndex === 2
                spacing: Constants.spacingXs
                Repeater {
                    model: 7
                    Common.CalendarButton {
                        required property int index
                        readonly property int weekday: index + 1
                        text: Qt.locale(Qt.uiLanguage).dayName(weekday % 7, Locale.ShortFormat)
                        checkable: true
                        checked: root.selectedWeekdays.includes(weekday)
                        highlighted: checked
                        onClicked: {
                            root.selectedWeekdays = checked ? root.selectedWeekdays.concat(weekday)
                                                           : root.selectedWeekdays.filter(day => day !== weekday);
                            root.changed();
                        }
                    }
                }
            }
            Label {
                visible: !root.providerEvent
                text: L.tr("Reminders in minutes", Qt.uiLanguage)
                color: Constants.textSecondary
            }
            Common.CalendarTextField {
                id: reminderInput
                visible: !root.providerEvent
                Layout.fillWidth: true
                placeholderText: "5, 30, 1440"
                Accessible.name: L.tr("Reminders in minutes", Qt.uiLanguage)
                onTextEdited: root.changed()
            }
            Label {
                Layout.fillWidth: true
                visible: !root.providerEvent
                text: L.tr("Separate reminder times with commas. Leave empty for no reminders.", Qt.uiLanguage)
                color: root.remindersValid ? Constants.textSecondary : Constants.error
                wrapMode: Text.WordWrap
            }
            Common.CalendarTextField {
                id: zoneInput
                Layout.fillWidth: true
                visible: !allDay.checked
                placeholderText: L.tr("Time zone, for example Asia/Baku", Qt.uiLanguage)
                Accessible.name: placeholderText
                onTextEdited: root.changed()
            }
            Common.SectionLabel {
                text: L.tr("Location and notes", Qt.uiLanguage)
                Layout.fillWidth: true
            }
            Common.CalendarTextField {
                id: locationInput
                Layout.fillWidth: true
                placeholderText: L.tr("Location", Qt.uiLanguage)
                onTextEdited: root.changed()
                Accessible.name: placeholderText
            }
            Common.CalendarTextArea {
                id: notesInput
                Layout.fillWidth: true
                Layout.preferredHeight: Constants.textAreaMinHeight
                placeholderText: L.tr("Description", Qt.uiLanguage)
                wrapMode: TextEdit.Wrap
                onTextChanged: root.changed()
                Accessible.name: placeholderText
            }
        }
    }
}
