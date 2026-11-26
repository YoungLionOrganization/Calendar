// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calendar
import "../Shared/DateUtils.mjs" as DateUtils
import "../Shared/I18n.js" as L

CalendarDialog {
    id: root
    property var selectedDate: new Date()
    signal dateRequested(int year, int monthIndex, int day)
    title: L.tr("Go to date", Qt.uiLanguage)
    footer: DialogButtonBox {
        CalendarButton {
            text: L.tr("Cancel", Qt.uiLanguage)
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
        }
        CalendarButton {
            text: L.tr("Go to date", Qt.uiLanguage)
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
        }
    }
    onOpened: {
        yearInput.value = selectedDate.getFullYear();
        monthInput.currentIndex = selectedDate.getMonth();
        dayInput.value = selectedDate.getDate();
    }
    onAccepted: root.dateRequested(yearInput.value, monthInput.currentIndex, dayInput.value)
    contentItem: ColumnLayout {
        spacing: Constants.spacingSm
        Label {
            text: L.tr("Year", Qt.uiLanguage)
            color: Constants.textPrimary
        }
        CalendarSpinBox {
            id: yearInput
            Layout.fillWidth: true
            from: 1900
            to: 2100
            editable: true
            locale: Qt.locale(Qt.uiLanguage)
            textFromValue: function (value, locale) {
                return String(value);
            }
            valueFromText: function (text, locale) {
                return Number(text);
            }
        }
        Label {
            text: L.tr("Month", Qt.uiLanguage)
            color: Constants.textPrimary
        }
        CalendarComboBox {
            id: monthInput
            Layout.fillWidth: true
            model: Array.from({
                length: 12
            }, (_, i) => Qt.locale(Qt.uiLanguage).standaloneMonthName(i, Locale.LongFormat))
        }
        Label {
            text: L.tr("Day", Qt.uiLanguage)
            color: Constants.textPrimary
        }
        CalendarSpinBox {
            id: dayInput
            Layout.fillWidth: true
            from: 1
            to: DateUtils.daysInMonth(yearInput.value, Math.max(0, monthInput.currentIndex))
            editable: true
        }
    }
}
