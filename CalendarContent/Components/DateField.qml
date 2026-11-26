// YoungLion Calendar
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Calendar
import "../Shared/DateUtils.mjs" as Dates
import "../Events/EventLogic.mjs" as Logic
import "../Shared/I18n.js" as L

ColumnLayout {
    id: root
    property string labelText: ""
    readonly property string dateKey: Logic.key(Dates.makeDate(yearBox.value, monthBox.currentIndex, dayBox.value))
    function setKey(k) {
        const d = Logic.date(k);
        yearBox.value = d.getFullYear();
        monthBox.currentIndex = d.getMonth();
        dayBox.value = d.getDate();
    }
    spacing: Constants.spacingXs
    Label {
        text: root.labelText
        color: Constants.textSecondary
        font.pixelSize: Constants.fontSizeLabel
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: Constants.spacingXs
        CalendarSpinBox {
            id: dayBox
            from: 1
            to: Dates.daysInMonth(yearBox.value, Math.max(0, monthBox.currentIndex))
            editable: true
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Accessible.name: L.tr("Day", Qt.uiLanguage)
        }
        CalendarComboBox {
            id: monthBox
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            model: Array.from({
                length: 12
            }, (_, i) => Qt.locale(Qt.uiLanguage).standaloneMonthName(i, Locale.ShortFormat))
            Accessible.name: L.tr("Month", Qt.uiLanguage)
        }
        CalendarSpinBox {
            id: yearBox
            from: 1900
            to: 2100
            value: 2026
            editable: true
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            textFromValue: function (value, locale) {
                return String(value);
            }
            valueFromText: function (text, locale) {
                return Number(text);
            }
            Accessible.name: L.tr("Year", Qt.uiLanguage)
        }
    }
}
